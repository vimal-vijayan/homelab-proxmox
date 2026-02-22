# Incident Report: Pod Egress & DNS Failure in k3s + Cilium (Multi-NIC Nodes)

## Status
✅ **Resolved**

- **Cluster:** k3s on Proxmox
- **CNI:** Cilium v1.18.5
- **kube-proxy:** Disabled (kubeProxyReplacement=true)
- **Date:** 2026-01-03

---

## 1. Summary

During the initial bootstrap of a **k3s cluster using Cilium with kube-proxy replacement**, pods scheduled on **worker nodes** were unable to access the internet (e.g. `github.com`, `ghcr.io`).

This caused:
- Transient failures in Flux installation
- DNS resolution errors inside pods

Host networking was working correctly, and pods on the **control-plane node worked by coincidence**, which initially masked the real issue.

The root cause was **missing SNAT (masquerading) for pod egress traffic** in a **multi-NIC node setup**.

---

## 2. Impact

### Affected
- Pods on worker nodes
- Flux Operator (artifact pulls from `ghcr.io`)
- DNS resolution from inside pods

### Not Affected
- Host OS networking
- Kubernetes API server
- Control-plane pods (worked accidentally)

---

## 3. Environment Details

### Cluster Networking
- **Pod CIDR:** `10.42.0.0/16`
- **Service CIDR:** `10.43.0.0/16`
- **CoreDNS Service IP:** `10.43.0.10`

### Node Networking (Multi-NIC)
Each node had two interfaces:

| Interface | Network | Purpose |
|---------|--------|---------|
| `ens18` | `192.168.178.0/24` | Home / Fritz network |
| `ens19` | `10.50.10.0/24` | pfSense / Lab network (intended egress) |

Nodes also had **two default routes**, creating ambiguity for CNI egress detection.

---

## 4. Symptoms

### From Pods (worker nodes)
```bash
curl https://github.com
# timeout

curl https://1.1.1.1
# timeout

From Hosts (same nodes)

curl https://github.com
# HTTP 200 (works)

Flux Operator Events

lookup ghcr.io on 10.43.0.10:53: no such host


⸻

5. Root Cause Analysis

Immediate Cause

Pod egress traffic was leaving the node without SNAT, using the pod IP (10.42.x.x) instead of the node IP.

Evidence (tcpdump)

10.42.1.12 → 1.1.1.1:443

Upstream gateways cannot route traffic back to pod CIDRs, causing connection timeouts.

⸻

Why It Worked on the Control Plane
	•	Cilium auto-detected the correct NIC by chance
	•	Different routing and startup timing
	•	Created a false sense of correctness

Control-plane success ≠ correct cluster configuration

⸻

Why enableIPv4Masquerade Was Not Enough

Although enabled, Cilium:
	•	Did not know which NIC was the correct external underlay
	•	Did not apply masquerade on ens19
	•	Fell back to ambiguous routing due to multi-NIC setup

⸻

6. Troubleshooting Steps

Step 1: Compare Host vs Pod Networking

# On node
curl https://github.com  # works

# In pod
curl https://github.com  # fails


⸻

Step 2: Eliminate DNS as Root Cause

curl https://1.1.1.1
# still fails → not DNS


⸻

Step 3: Capture Egress Traffic

tcpdump -ni ens19 host 1.1.1.1

Observed:

SRC = 10.42.x.x

✔ Confirmed missing SNAT

⸻

Step 4: Check rp_filter (Ruled Out)

sysctl net.ipv4.conf.*.rp_filter

	•	Value was 2 (loose)
	•	Disabling did not resolve the issue

⸻

7. Fix Applied (Permanent)

Final Cilium Installation Command

cilium install --version 1.18.5 \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=10.50.10.10 \
  --set k8sServicePort=6443 \
  --set ipam.operator.clusterPoolIPv4PodCIDRList="10.42.0.0/16" \
  --set enableIPv4Masquerade=true \
  --set bpf.masquerade=true \
  --set devices=ens19 \
  --set routingMode=tunnel \
  --set tunnelProtocol=vxlan

Why This Works
	•	enableIPv4Masquerade=true → allows SNAT
	•	bpf.masquerade=true → enforces SNAT in eBPF (reliable)
	•	devices=ens19 → deterministic egress interface
	•	Eliminates multi-NIC ambiguity

⸻

8. Verification

Pod Egress Test (All Nodes)

curl https://1.1.1.1
# HTTP 301 (success)

curl https://github.com
# HTTP 200

tcpdump Confirmation

10.50.10.x → 1.1.1.1

✔ SNAT working correctly

⸻

9. Flux Verification

kubectl get fluxinstances -n flux-system

Result:

READY: True
STATUS: ReconciliationSucceeded

The earlier ArtifactFailed event was transient and resolved automatically once networking was fixed.

⸻

10. Lessons Learned

Key Takeaways
	•	Multi-NIC Kubernetes nodes require explicit CNI configuration
	•	Do not rely on auto-detection for production-like setups
	•	Always validate pod egress explicitly
	•	Control-plane success can hide worker-node issues

Recommended Defaults for Cilium + Multi-NIC

enableIPv4Masquerade: true
bpf.masquerade: true
devices: <primary-egress-interface>


⸻

11. Final Status

✅ Pod networking stable
✅ DNS stable
✅ Flux fully operational
✅ Issue documented and reproducible

⸻
