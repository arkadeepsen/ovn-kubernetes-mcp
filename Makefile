# Get the Git repository root directory
GIT_ROOT := $(shell git rev-parse --show-toplevel)

export MCP_SERVER_PATH := $(GIT_ROOT)/_output/ovnk-mcp-server

.PHONY: build
build:
	go build -o $(MCP_SERVER_PATH) cmd/ovnk-mcp-server/main.go

.PHONY: clean
clean:
	rm -Rf _output/

