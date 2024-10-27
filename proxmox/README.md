# Proxmox

Proxmox Virtual Environment (VE) is booted on the Intel NUC. The router uses IP addresses in the range of 100-250 for DHCP. The Proxmox server gets a static IP address: 251, so it doesn't conflict for devices that receive a dynamic IP address.

## Connectivity troubleshooting

Make sure that the network interface that connects to Wi-Fi is not configured in `/etc/network/interfaces` (comment out conflicting interfaces). Configure a static IP address using `nmcli connection modify`. The resulting config can be observed in `/etc/NetworkManager/system-connections/`. It might be necessary to `sudo systemctl restart NetworkManager`.
