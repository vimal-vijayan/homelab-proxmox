# Homelab: Proxmox + Production-Ready K3s

This repository documents my homelab built on Proxmox with the goal of running a fully secure, production-ready K3s (lightweight Kubernetes) cluster. It includes network design, Terraform infrastructure pieces, and plans for SIEM and layered security best practices suitable for a small-but-serious environment.

## Quick Links
- [Proxmox Setup (detailed)](proxmox/docs/proxmox.setup.README.md)
- [Ubuntu server Setup](proxmox/docs/vm.setup.readme.md)
- [pfSense Terraform configs](proxmox/terraform/pfsense)
- [Kubernetes Terraform configs](proxmox/terraform/kubernetes)
- [Network diagrams](proxmox/docs/drawio/)


## Overview
- Purpose: Learn, prototype, and operate a hardened K3s platform at home.
- Platform: Proxmox for virtualization; pfSense for routing/firewall; VMs for K3s control-plane and workers.
- Networking: Segmented VLANs, hub-spoke topology, MetalLB for L2 load balancing.
- Focus: Security-first setup (policies, runtime protection, vulnerability scanning, secrets management) and full observability (logs, metrics, traces) plus SIEM.

## Architecture
- Proxmox host(s) virtualize the stack.
- pfSense VM provides firewall, NAT, DHCP, and inter-VLAN routing.
- K3s cluster runs on VM nodes (1–3 control-plane, 2+ workers depending on capacity).
- Load balancing via MetalLB (L2 mode) for services that need stable IPs.
- Storage: Longhorn (recommended) or NFS for persistent workloads.
- Network segmentation: management, cluster, workload, and DMZ segments.

## Diagrams
- [Hub-spoke and routing diagrams](proxmox/docs/drawio/)
- [Proxmox network routes](proxmox/docs/drawio/)


## Proxmox Setup
For a step-by-step Proxmox installation and configuration walkthrough, see the detailed guide in the `proxmox` folder:
- [Primary guide](proxmox/docs/proxmox.setup.README.md)
- [VM provisioning details](proxmox/docs/vm.setup.readme.md)
- [Diagrams (hub-spoke, routes)](proxmox/docs/drawio/)

Infrastructure as Code (optional):
- [pfSense Terraform configs](proxmox/terraform/pfsense)
- [Kubernetes Terraform configs](proxmox/terraform/kubernetes)

## K3s Deployment Steps
1. [configure vms in Proxmox with Ubuntu server 22.04 LTS.](proxmox/docs/vm.setup.readme.md)
2. #TODO: Configure pfSense for VLANs, DHCP, and routing as per the network design.
3. [Setup k3s cluster and Cni plugin (Cilium)](k3s/docs/k3s.setup.readme.md). 
4. [Setup MetalLB in Layer 2 mode for load balancing.](metalLB/readme.md)


## Security & SIEM Plan
The goal is a defense-in-depth approach aligned with common best practices and CIS benchmarks.

Baseline Hardening
- OS hardening on Proxmox/pfSense and all K3s nodes (SSH, users, patching).
- Strict network ACLs and VLAN separation; default deny on east-west traffic where practical.
- TLS everywhere; enable mTLS within service mesh (optional, e.g., Istio/Linkerd) for zero-trust between services.

Kubernetes Security Layers
- Policies: Kyverno or OPA Gatekeeper to enforce baseline (non-root, read-only FS, seccomp, capabilities drop, resource limits).
- Runtime detection: Falco to detect suspicious behavior at the node/pod level.
- Vulnerability scanning: Trivy (images, filesystems, and Kubernetes resources) with regular scans and PR gates.
- Benchmarks: kube-bench (CIS), kube-hunter for reconnaissance checks.
- Secrets: Sealed Secrets or SOPS (age) with GitOps; never store plaintext secrets.
- Supply chain: cosign for image signing/verification; SBOM generation and tracking.
- Network policy: Calico or Cilium to enforce fine-grained pod-level traffic rules.

Observability & SIEM
- Logs: Loki or OpenSearch for centralized logging; cluster/system logs shipped via Promtail/Vector/Fluent Bit.
- Metrics: Prometheus + Alertmanager; dashboards in Grafana.
- Tracing: OpenTelemetry collectors to instrument key services.
- SIEM: Wazuh or Security Onion to aggregate events (auth, network, IDS, host logs) and drive detections & response.

Backup & DR
- Velero for cluster backups (ETCD state via K3s, plus namespace resources/PVC snapshots when supported).
- Regular snapshots of Proxmox VMs and pfSense config exports.



## Current Status
- Finish Proxmox/pfSense networking and VLAN routing.
- Bootstrap K3s control-plane and worker nodes.
- Deploy core platform (CNI, MetalLB, ingress, cert-manager, storage).
- Roll out the security stack (Kyverno/Gatekeeper, Falco, Trivy, secrets).
- Stand up observability (Prometheus/Grafana, Loki) and SIEM (Wazuh/Security Onion).
- Enable GitOps and automated backups.

## Future Enhancements
- Explore service mesh (Istio/Linkerd) for mTLS and advanced traffic management.
- Security and SIEM Planning
## References
- K3s: https://k3s.io/
- MetalLB: https://metallb.universe.tf/
- pfSense: https://www.pfsense.org/
- Kyverno: https://kyverno.io/ | Gatekeeper: https://open-policy-agent.github.io/gatekeeper/
- Falco: https://falco.org/ | Trivy: https://aquasecurity.github.io/trivy/
- Longhorn: https://longhorn.io/ | Velero: https://velero.io/
- Wazuh: https://wazuh.com/ | Security Onion: https://securityonionsolutions.com/
