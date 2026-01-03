# Install the Flux Operator

The Flux Operator can be installed in a Kubernetes cluster using the following command:

```bash
helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  --namespace flux-system \
  --create-namespace
```

## Configure the Flux Instance 

if the git repository is private, create a pull secret for authentication:

```bash
export GITHUB_TOKEN=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

flux create secret git flux-system \
  --url=https://github.com/vimal-vijayan/homelab-proxmox.git \
  --username=git \
  --password=$GITHUB_TOKEN

# Install the Flux Operator

The Flux Operator can be installed in a Kubernetes cluster using the following command:

```bash
helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
    --namespace flux-system \
    --create-namespace
```

## Configure the Flux Instance 

if the git repository is private, create a pull secret for authentication:

```bash
export GITHUB_TOKEN=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

flux create secret git flux-system \
    --url=https://github.com/vimal-vijayan/homelab-proxmox.git \
    --username=git \
    --password=$GITHUB_TOKEN
```

Alternatively, using kubectl:

```bash
kubectl create secret generic flux-system \
    --namespace flux-system \
    --from-literal=username=git \
    --from-literal=password=$GITHUB_TOKEN
```

After installing the Flux Operator, you need to create a `Flux` custom resource to configure your Flux instance. Below is an example YAML configuration:

```yaml
apiVersion: fluxcd.controlplane.io/v1
kind: FluxInstance
metadata:
    name: flux
    namespace: flux-system
    annotations:
        fluxcd.controlplane.io/reconcileEvery: "1h"
        fluxcd.controlplane.io/reconcileTimeout: "5m"
spec:
    distribution:
        version: "2.7.x"
        registry: "ghcr.io/fluxcd"
        artifact: "oci://ghcr.io/controlplaneio-fluxcd/flux-operator-manifests"
    components:
        - source-controller
        - kustomize-controller
        - helm-controller
        - notification-controller
        - image-reflector-controller
        - image-automation-controller      
    sync:
        kind: GitRepository
        url: "https://github.com/vimal-vijayan/homelab-proxmox.git"
        ref: "refs/heads/main"
        path: "clusters/my-cluster"
        pullSecret: "flux-system"
```

```

After installing the Flux Operator, you need to create a `Flux` custom resource to configure your Flux instance. Below is an example YAML configuration:

```yaml
apiVersion: fluxcd.controlplane.io/v1
kind: FluxInstance
metadata:
  name: flux
  namespace: flux-system
  annotations:
    fluxcd.controlplane.io/reconcileEvery: "1h"
    fluxcd.controlplane.io/reconcileTimeout: "5m"
spec:
  distribution:
    version: "2.7.x"
    registry: "ghcr.io/fluxcd"
    artifact: "oci://ghcr.io/controlplaneio-fluxcd/flux-operator-manifests"
  components:
    - source-controller
    - kustomize-controller
    - helm-controller
    - notification-controller
    - image-reflector-controller
    - image-automation-controller      
  sync:
    kind: GitRepository
    url: "https://github.com/vimal-vijayan/homelab-proxmox.git"
    ref: "refs/heads/main"
    path: "clusters/my-cluster"
    pullSecret: "flux-system"
```
