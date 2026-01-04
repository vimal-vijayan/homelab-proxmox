# Install the Flux Operator

The Flux Operator can be installed in a Kubernetes cluster using the following command:

```bash
helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  --namespace flux-system \
  --create-namespace
```

# Configure Git Authentication

## You could either use the git token or create a github app and use the installation token for authentication.

Since I am in github, I will create a github app and use the private key to generate the installation token.

## Configure the git authentication secret
```bash
export GITHUB_APP_ID=123456
export GITHUB_INSTALLATION_ID=654321
export GITHUB_PRIVATE_KEY_PATH=/path/to/private-key.pem

# Flux command
flux create secret githubapp flux-system \
  --app-id=1 \
  --app-installation-id=2 \
  --app-private-key=./path/to/private-key-file.pem

# Alternatively, using kubectl
kubectl create secret generic git-token-auth \
  --namespace flux-system \
  --from-literal=githubAppID=$GITHUB_APP_ID \
  --from-literal=githubInstallationID=$GITHUB_INSTALLATION_ID \
  --from-file=githubAppPrivateKey=$GITHUB_PRIVATE_KEY_PATH
```

Install the github app in the desired repositories or organizations to give access to Flux.


## Configure the Flux Instance 

After installing the Flux Operator, you need to create a `Flux` custom resource to configure your Flux instance. Below is an example YAML configuration:

For detailed cluster sync configuration options, see the [Flux Operator documentation](https://fluxoperator.dev/docs/instance/sync/).

```yaml
apiVersion: fluxcd.controlplane.io/v1
kind: FluxInstance
metadata:
  name: flux
  namespace: flux-system
spec:
  distribution:
    version: "2.7.x"
    registry: "ghcr.io/fluxcd"
  components:
    - source-controller
    - kustomize-controller
    - helm-controller
    - notification-controller
    - image-reflector-controller
    - image-automation-controller
  sync:
    kind: GitRepository
    provider: github
    url: "https://github.com/my-org/my-fleet.git"
    ref: "refs/heads/main"
    path: "clusters/my-cluster"
    pullSecret: "flux-system"
```
