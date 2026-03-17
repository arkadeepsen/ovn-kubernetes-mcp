# Get the Git repository root directory
export GIT_ROOT := $(shell git rev-parse --show-toplevel)

export MCP_SERVER_PATH := $(GIT_ROOT)/_output/ovnk-mcp-server
KUBECONFIG ?= $(HOME)/ovn.conf
export KUBECONFIG

# CONTAINER_RUNNABLE determines if the tests can be run inside a container. It checks to see if
# podman/docker is installed on the system.
PODMAN ?= $(shell podman -v > /dev/null 2>&1; echo $$?)
ifeq ($(PODMAN), 0)
CONTAINER_RUNTIME?=podman
else
CONTAINER_RUNTIME?=docker
endif
CONTAINER_RUNNABLE ?= $(shell $(CONTAINER_RUNTIME) -v > /dev/null 2>&1; echo $$?)

export CONTAINER_RUNTIME

GOPATH ?= $(shell go env GOPATH)

.PHONY: build
build:
	go build -o $(MCP_SERVER_PATH) cmd/ovnk-mcp-server/main.go

# Container image build targets (use IMAGE to override tag, e.g. make build-image IMAGE=quay.io/myorg/ovnk-mcp-server:v1.0)
IMAGE ?= localhost/ovnk-mcp-server:dev
export IMAGE
GOLANG_IMAGE ?= quay.io/projectquay/golang
GOLANG_VERSION ?= 1.24

.PHONY: build-image
build-image:
	$(CONTAINER_RUNTIME) build -f Dockerfile \
		--build-arg GOLANG_IMAGE=$(GOLANG_IMAGE) \
		--build-arg GOLANG_VERSION=$(GOLANG_VERSION) \
		-t $(IMAGE) .

.PHONY: deploy-k8s
deploy-k8s:
	@mkdir -p _output/kustomize-deploy
	IMAGE='$(IMAGE)' envsubst '$$IMAGE' < config/image-patch.yaml.tpl > _output/kustomize-deploy/image-patch.yaml
	cp config/kustomization.deploy.yaml.tpl _output/kustomize-deploy/kustomization.yaml
	kubectl kustomize _output/kustomize-deploy | kubectl apply -f -

.PHONY: undeploy-k8s undeploy
undeploy-k8s undeploy:
	kubectl delete -k config/

.PHONY: clean
clean:
	rm -Rf _output/

EXCLUDE_DIRS ?= test/
TEST_PKGS := $$(go list ./... | grep -v $(EXCLUDE_DIRS))

.PHONY: test
test:
	go test -v $(TEST_PKGS)

.PHONY: deploy-kind-ovnk
deploy-kind-ovnk:
	./hack/deploy-kind-ovnk.sh

.PHONY: undeploy-kind-ovnk
undeploy-kind-ovnk:
	./hack/undeploy-kind-ovnk.sh

NVM_VERSION := 0.40.3
NODE_VERSION := 22.20.0
NPM_VERSION := 11.6.1
GINKGO_VERSION := v2.26.0
MCP_MODE ?= live-cluster

.PHONY: run-e2e
run-e2e:
	./hack/run-e2e.sh $(NVM_VERSION) $(NODE_VERSION) $(NPM_VERSION) $(GINKGO_VERSION) "$(MCP_MODE)" "$(FOCUS)"

.PHONY: test-e2e
test-e2e: build
	if [ "$(MCP_MODE)" = "live-cluster" ]; then $(MAKE) deploy-kind-ovnk || exit 1; fi; \
	$(MAKE) run-e2e || EXIT_CODE=$$?; \
	if [ "$(MCP_MODE)" = "live-cluster" ]; then $(MAKE) undeploy-kind-ovnk || exit 1; fi; \
	exit $${EXIT_CODE:-0}

.PHONY: lint
lint:
ifeq ($(CONTAINER_RUNNABLE), 0)
	@GOPATH=${GOPATH} ./hack/lint.sh $(CONTAINER_RUNTIME) || { echo "lint failed! Try running 'make lint-fix'"; exit 1; }
else
	echo "linter can only be run within a container since it needs a specific golangci-lint version"; exit 1
endif

.PHONY: update-readme-tools
update-readme-tools:
	go run ./hack/gen-readme-tools.go

.PHONY: lint-fix
lint-fix:
ifeq ($(CONTAINER_RUNNABLE), 0)
	@GOPATH=${GOPATH} ./hack/lint.sh ${CONTAINER_RUNTIME} fix || { echo "ERROR: lint fix failed! There is a bug that changes file ownership to root \
	when this happens. To fix it, simply run 'chown -R <user>:<group> *' from the repo root."; exit 1; }
else
	echo "linter can only be run within a container since it needs a specific golangci-lint version"; exit 1
endif
