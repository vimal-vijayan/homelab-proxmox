Nice, this is exactly the kind of thing Proxmox is great for 😄
Let’s design a simple but powerful lab network:
	•	Subnet A – Infra / jump hosts / Terraform
	•	Subnet B – Kubernetes cluster
	•	Subnet C – Other experiments / DMZ / whatever you want

All routed & firewalled by a virtual firewall (pfSense/OPNsense) running on Proxmox.

I’ll assume:
	•	Your Fritz!Box is still your home router (192.168.178.1)
	•	Proxmox host is at 192.168.178.44 on vmbr0
	•	You have just 1 cable from Fritz!Box → Proxmox (that’s fine)

⸻

1️⃣ Network Design (subnets)

Let’s use these private ranges:
	•	Subnet A – Infra / Jump / Terraform
10.10.10.0/24  → gateway 10.10.10.1
	•	Subnet B – Kubernetes
10.20.20.0/24  → gateway 10.20.20.1
	•	Subnet C – Lab / DMZ / misc
10.30.30.0/24  → gateway 10.30.30.1

The gateway IPs will live on your firewall VM.

Your Fritz!Box + home devices stay on 192.168.178.0/24.

⸻

2️⃣ Create internal networks in Proxmox

In the Proxmox UI:

Node → Network

You already have:
	•	vmbr0 – bridge to physical NIC, IP 192.168.178.44/24, GW 192.168.178.1

Now create three new Linux bridges (no physical ports):

🔹 Create vmbr1 – Infra LAN
	1.	Click Create → Linux Bridge
	2.	Name: vmbr1
	3.	Bridge ports: (leave empty)
	4.	IPv4: None (we’ll let the firewall own this subnet)
	5.	VLAN aware: No (for now)
	6.	OK

🔹 Create vmbr2 – Kubernetes LAN

Same steps:
	•	Name: vmbr2
	•	Bridge ports: (empty)
	•	IPv4: None

🔹 Create vmbr3 – Lab / DMZ
	•	Name: vmbr3
	•	Bridge ports: (empty)
	•	IPv4: None

Then click Apply Configuration (top right).
If it asks for reboot, you can reboot – it’s safe.

Now you have 4 bridges:
	•	vmbr0 – WAN / home network (to Fritz!Box)
	•	vmbr1 – Infra network (10.10.10.0/24)
	•	vmbr2 – Kubernetes network (10.20.20.0/24)
	•	vmbr3 – DMZ / misc (10.30.30.0/24)

⸻

3️⃣ Create your firewall VM (pfSense is a good choice)

Create a new VM:
	1.	Create VM → Name: pfsense
	2.	OS: “Do not use any media” or use pfSense ISO if you already uploaded it.
	3.	System: keep defaults (UEFI/BIOS OK).
	4.	Disks / CPU / RAM: e.g. 2 vCPU, 4GB RAM, 20–40GB disk.

Now the important part: Network.

On the Hardware tab of that VM, configure NICs:

NIC 1 – WAN
	•	Bridge: vmbr0
	•	Model: VirtIO (or Intel E1000 if pfSense prefers)
	•	This goes to Fritz!Box network (192.168.178.x)

NIC 2 – INFRA LAN
	•	Add → Network Device
	•	Bridge: vmbr1
	•	This will be 10.10.10.0/24

NIC 3 – K8s LAN
	•	Add → Network Device
	•	Bridge: vmbr2
	•	This will be 10.20.20.0/24

NIC 4 – LAB / DMZ
	•	Add → Network Device
	•	Bridge: vmbr3
	•	This will be 10.30.30.0/24

Now attach the pfSense ISO and install it.

⸻

4️⃣ Configure networks inside pfSense

During pfSense setup:
	1.	Assign interfaces:
	•	WAN → the NIC on vmbr0 (it will get an IP from Fritz!Box via DHCP)
	•	LAN → NIC on vmbr1
	•	OPT1 → NIC on vmbr2
	•	OPT2 → NIC on vmbr3
	2.	Set IPs:
	•	LAN (vmbr1): 10.10.10.1/24
	•	OPT1 (vmbr2): 10.20.20.1/24
	•	OPT2 (vmbr3): 10.30.30.1/24
	3.	Enable DHCP servers (optional but handy):
	•	On LAN → range 10.10.10.50 – 10.10.10.200
	•	On OPT1 → 10.20.20.50 – 10.20.20.200
	•	On OPT2 → 10.30.30.50 – 10.30.30.200

By default pfSense will NAT all internal networks to the WAN, so all your subnets will have Internet.

⸻

5️⃣ Attach VMs to the right subnet

Now when you create VMs:

🔹 Kubernetes control-plane / workers

In each K8s VM:
	•	Network bridge: vmbr2
	•	They’ll get IPs from 10.20.20.0/24 via pfSense
	•	Gateway: 10.20.20.1

🔹 Jump server / Terraform / infra tools
	•	Bridge: vmbr1
	•	IP: 10.10.10.x
	•	Gateway: 10.10.10.1

🔹 Other lab/DMZ services
	•	Bridge: vmbr3
	•	IP: 10.30.30.x
	•	Gateway: 10.30.30.1

Each subnet is isolated unless you create firewall rules in pfSense to allow traffic between them (e.g. Jump host → K8s nodes only via SSH).

⸻

6️⃣ How do YOU reach those VMs from your laptop?

Your laptop is still on 192.168.178.x (home network).

Options:
	1.	Use pfSense as a VPN server (OpenVPN or WireGuard)
	•	You VPN into pfSense → you get an IP in Infra subnet → you can SSH into all subnets.
	•	Clean and secure.
	2.	Add static routes on Fritz!Box (if supported by your model)
	•	Route 10.10.10.0/24, 10.20.20.0/24, 10.30.30.0/24 via pfSense WAN IP.
	•	Then your laptop can directly reach those networks.
	3.	Use a jump server on vmbr1
	•	SSH/RDP into the jump server from home network (if you port-forward one port).
	•	From jump server, go everywhere.

I’d recommend VPN → pfSense for a clean lab setup.

⸻

7️⃣ What you have now
	•	Proxmox host reachable on 192.168.178.44
	•	pfSense VM routing between:
	•	WAN: 192.168.178.0/24
	•	LAN A (Infra): 10.10.10.0/24
	•	LAN B (K8s): 10.20.20.0/24
	•	LAN C (Lab/DMZ): 10.30.30.0/24
	•	You can place VMs into the subnet that matches their role.

⸻

If you’d like, next I can:
	•	Design firewall rules between these subnets (e.g. only allow SSH from Infra → K8s)
	•	Help you create the first K8s node VM on vmbr2
	•	Help you set up a jump host or VPN into pfSense

Tell me which one you want to do next, and we’ll continue from there.