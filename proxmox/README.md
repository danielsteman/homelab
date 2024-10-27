# Proxmox

Proxmox Virtual Environment (VE) is booted on the Intel NUC. The router uses IP addresses in the range of 100-250 for DHCP. The Proxmox server gets a static IP address: 251, so it doesn't conflict for devices that receive a dynamic IP address.

## Virtual machines

[Debian image](https://www.debian.org/distrib/)

## Networking

Create a bridged network interface in `/etc/network/interfaces`:

```
auto vmbr0
iface vmbr0 inet static
    address 10.0.2.1
    netmask 255.255.255.0
    bridge_ports none
    bridge_stp off
    bridge_fd 0
```

Enable IP forwarding

```bash
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

Allow traffic from `vmbr0` to `wlp1s0`:

```bash
sudo iptables -t nat -A POSTROUTING -s 10.0.2.0/24 -o wlp1s0 -j MASQUERADE
```

## Connectivity troubleshooting

Make sure that the network interface that connects to Wi-Fi is not configured in `/etc/network/interfaces` (comment out conflicting interfaces). Configure a static IP address using `nmcli connection modify`. The resulting config can be observed in `/etc/NetworkManager/system-connections/`. It might be necessary to `sudo systemctl restart NetworkManager`.
