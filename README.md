# Homelab: Proxmox + Production-Ready K3s

This repository documents a homelab platform built on Proxmox to run a secure, production-oriented K3s cluster with strong network segmentation, centralized firewalling, and an incremental security/observability stack.

## Goals

- Build and operate a hardened K3s platform in a home lab.
- Route all inter-network traffic through pfSense for policy enforcement.
- Keep cluster and internal nodes private (no direct public exposure).
- Implement defense-in-depth controls and SIEM-ready telemetry.

## Architecture At A Glance

- Proxmox provides virtualization for infrastructure VMs.
- pfSense VM provides routing, firewalling, NAT, DHCP, and VPN termination.
- K3s runs on Ubuntu VMs (control-plane and workers).
- MetalLB provides stable service IPs for L2 load balancing.
- Network design follows segmented hub-spoke style networks.

## Recommended Build Order

1. Set up Proxmox host networking and VM base images.
2. **Start MinIO for Terraform state storage** (see [MinIO setup](#minio-terraform-state-backend) below).
3. Deploy and configure pfSense interfaces, DNS, firewall rules, and WireGuard.
4. Provision Ubuntu VMs for K3s control-plane and workers.
5. Install K3s with Cilium CNI.
6. Configure MetalLB for service exposure on internal networks.
7. Add security, observability, backup, and SIEM components.

## MinIO Terraform State Backend

All Terraform projects in this repo use a local MinIO instance as the S3-compatible state backend. MinIO must be running before any `terraform init` or `terraform apply`.

### Start MinIO

```bash
cd utilities/Minio
docker compose up -d
```

MinIO API runs on `http://localhost:9000`, console at `http://localhost:9001` (credentials: `minioadmin` / `minioadmin`).

### Create the state bucket (first-time only)

```bash
# Using the MinIO client (mc)
brew install minio/stable/mc
mc alias set local http://localhost:9000 minioadmin minioadmin
mc mb local/terraform-state
```

Or open the console at `http://localhost:9001` and create a bucket named `terraform-state`.

### Initialize a Terraform project against MinIO

```bash
cd <terraform-project-dir>
terraform init          # first time
# or, if migrating existing local state:
terraform init -migrate-state
```

State files are stored per-project under the `terraform-state` bucket using the key path defined in each project's `backend "s3"` block (e.g. `proxmox-mgmt-tailscale/terraform.tfstate`).

## Documentation Map

- [Proxmox setup](docs/proxmox/docs/proxmox.setup.README.md)
- [VM setup (Ubuntu)](docs/proxmox/docs/vm.setup.readme.md)
- [Proxmox network design](docs/proxmox/docs/proxmox.setup.README.md#3️⃣-network-design-and-configuration)
- [Network diagrams](docs/proxmox/docs/drawio/)
- [pfSense firewall setup (manual)](docs/firewall/pfsense/README.md)
- [pfSense Terraform (optional)](docs/proxmox/terraform/pfsense)
- [Kubernetes Terraform (optional)](docs/proxmox/terraform/kubernetes)
- [K3s setup](docs/k3s/docs/k3s.setup.readme.md)
- [K3s networking notes](docs/k3s/docs/k3s.network.readme.md)
- [MetalLB setup](docs/metalLB/README.md)

## Security And SIEM Strategy

### Baseline Hardening

- Harden Proxmox, pfSense, and all K3s nodes (users, SSH, patching).
- Enforce network segmentation with least-privilege firewall policy.
- Use TLS by default and add mTLS where appropriate.

### Kubernetes Security Layers

- Policy enforcement: Kyverno or OPA Gatekeeper.
- Runtime detection: Falco.
- Vulnerability scanning: Trivy.
- Benchmarking and checks: kube-bench and kube-hunter.
- Secrets management: Sealed Secrets or SOPS (age).
- Supply chain controls: cosign and SBOM workflows.
- Pod traffic policy: Cilium (or Calico, if required).

### Observability And SIEM

- Logs: Loki or OpenSearch with log shippers.
- Metrics and alerting: Prometheus + Alertmanager + Grafana.
- Tracing: OpenTelemetry collector pipeline.
- SIEM: Wazuh or Security Onion for correlation and detection.

### Backup And DR

- Cluster backup: Velero.
- Infrastructure backup: Proxmox snapshots and pfSense config exports.

## Current Status

- Proxmox foundation and documentation are in place.
- pfSense manual setup documentation is in place.
- K3s and platform components are being iteratively integrated.

## Next Milestones

- Complete end-to-end VLAN/routing validation across all segments.
- Finish K3s bootstrap and node joining.
- Deploy ingress, cert-manager, storage, and baseline policies.
- Integrate observability and SIEM pipelines.
- Enable GitOps and automated backup routines.

## References

- [K3s](https://k3s.io/)
- [Cilium](https://cilium.io/)
- [MetalLB](https://metallb.universe.tf/)
- [pfSense](https://www.pfsense.org/)
- [Kyverno](https://kyverno.io/)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)
- [Falco](https://falco.org/)
- [Trivy](https://aquasecurity.github.io/trivy/)
- [Longhorn](https://longhorn.io/)
- [Velero](https://velero.io/)
- [Wazuh](https://wazuh.com/)
- [Security Onion](https://securityonionsolutions.com/)
