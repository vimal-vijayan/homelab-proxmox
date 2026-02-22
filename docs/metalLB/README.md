# Install MetalLB using Helm

```bash
kubectl create namespace metallb-system

helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb -n metallb-system
```

## Configure MetalLB ip address pool
Create a ConfigMap with the desired IP address pool for MetalLB. Replace the IP range with one that fits your network.

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: home-lab-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.50.10.100/32
---
```

## Configure MetalLB L2 Advertisement
```yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: home-lab-l2adv
  namespace: metallb-system
spec:
  ipAddressPools:
  - home-lab-pool
```

# Apply the configuration:

```bash
kubectl apply -f metallb-ip-pool.yaml
``` 

## Verify MetalLB is working
You can verify that MetalLB is functioning correctly by creating a LoadBalancer service and checking if it gets an IP from the defined pool.

## Sample LoadBalancer Service
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: default
  annotations:
    metallb.io/address-pool: home-lab-pool
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: nginx
  type: LoadBalancer
```