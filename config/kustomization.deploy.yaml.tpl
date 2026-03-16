# Deploy overlay: base config + image override from IMAGE (envsubst at deploy time).
# Rendered to _output/kustomize-deploy/ by make deploy-k8s.
# Default image is defined only in config/deployment.yaml; this overlay only overrides it.
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../config
patches:
  - path: image-patch.yaml
