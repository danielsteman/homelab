# K3s Worker 1 (Proxmox VM)
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
  networking.hostName = "k3s-worker-1";

  # Network
  networking.useDHCP = false;
  networking.interfaces.ens18.useDHCP = true;

  # K3s worker config
  services.k3s = {
    role = "agent";
    # Update with your master IP after master is installed
    serverAddr = "https://10.0.2.10:6443";  # TODO: Update IP after master setup
    # tokenFile = config.sops.secrets.k3s-token.path;  # Enable after SOPS setup
    # Or set token directly: token = "YOUR_TOKEN_HERE";
    extraFlags = toString [
      "--node-label=node.kubernetes.io/arch=amd64"
      "--node-label=node.kubernetes.io/type=proxmox-vm"
    ];
  };
}
