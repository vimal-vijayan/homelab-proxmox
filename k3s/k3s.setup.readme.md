# K3S Quick Setup Guide 

## K3S Server quick setup

```₹bash
curl -sfL https://get.k3s.io | sh -s - server \
  --node-ip=<serverip>\
  --advertise-address=<serverip> \
  --tls-san=<serverip-for-external-access> 
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

