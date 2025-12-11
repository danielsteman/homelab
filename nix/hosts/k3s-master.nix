# K3s Master Node (Proxmox VM)
{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    ../modules/common.nix
    ../modules/k3s-node.nix
  ];

  # Boot (Proxmox VM)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hostname
  networking.hostName = "k3s-master";

  # Network (Proxmox VM - adjust interface name)
  networking.useDHCP = false;
  networking.interfaces.ens18.useDHCP = true;  # Proxmox default NIC

  # K3s master config
  services.k3s = {
    role = "server";
    clusterInit = true;  # First master
  };

  # Additional firewall ports for master
  networking.firewall.allowedTCPPorts = [
    2379  # etcd client
    2380  # etcd peer
  ];
}
