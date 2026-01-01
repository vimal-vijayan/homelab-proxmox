# K3S Quick Setup Guide 

## K3S Server quick setup

```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --node-ip=<serverip>\
  --advertise-address=<serverip> \
  --tls-san=<serverip-for-external-access> 

example : 

curl -sfL https://get.k3s.io | sh -s - server --node-ip=10.50.10.10 --advertise-address=10.50.10.10 --tls-san=192.168.178.53 --flannel-backend=none --disable-network-policy --disable=traefik --disable=servicelb --tls-san=10.50.10.10
```

The token for agent nodes to join the cluster can be found at `/var/lib/rancher/k3s/server/node-token` on the server node.

## K3S Agent quick setup
```bash
curl -sfL https://get.k3s.io | K3S_URL=https://<serverip>:6443 sh -s - agent --token <token> --node-ip <agentip>
```

## Copy the kubeconfig file from the server node to your local machine
```bash
cp /etc/rancher/k3s/k3s.yaml ~/home/
chown $(id -u):$(id -g) ~/home/k3s.yaml
scp user@<serverip>:~/home/k3s.yaml ~/.kube/config ## adjust the command as needed, the scp command may overwrite your existing kubeconfig file
```

## update the kubeconfig for the cluster context to be available externally
```bash
k config set-cluster default --server=https://192.168.178.53:6443
```

## Verify the nodes are ready
```bash
k get nodes -o wide
```

k3s comes up with traefik as the default ingress controller. You can verify that the traefik pods are running by executing:
```bash
k get pods -n kube-system
```

if you want to disable traefik during the server setup, you can add the `--disable traefik` flag to the server installation command. or update the config.yaml file located at `/etc/rancher/k3s/config.yaml` with the following content:
```yaml
disable:
  - traefik
```

