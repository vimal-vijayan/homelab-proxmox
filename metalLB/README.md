# Metal LB Installation and Setup



## Install MetalLB using helm

```bash
kubectl create namespace metallb-system

helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb -n metallb-system
```