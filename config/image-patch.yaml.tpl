# Strategic merge patch: override container image with IMAGE at deploy time.
# Rendered to _output/kustomize-deploy/image-patch.yaml by make deploy-k8s.
# Default image remains the single source of truth in config/deployment.yaml.
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ovnk-mcp-server
  namespace: ovn-kubernetes-mcp
spec:
  template:
    spec:
      containers:
        - name: ovnk-mcp-server
          image: ${IMAGE}
