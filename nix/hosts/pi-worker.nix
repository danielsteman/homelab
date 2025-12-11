# Raspberry Pi Worker Node
{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    ../modules/common.nix
    ../modules/k3s-node.nix
    ../hardware-configuration.nix
  ];

  # Boot
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible = {
    enable = true;
    device = "nodev";
  };

  # Raspberry Pi hardware
  boot.kernelPackages = pkgs.linuxPackages_rpi4;

  # Hostname
  networking.hostName = "pi-worker";

  # Network
  networking.useDHCP = lib.mkDefault true;
  networking.wireless.iwd.enable = true;  # WiFi support

  # K3s worker config
  services.k3s = {
    role = "agent";
    # Update with your master IP after master is installed
    serverAddr = "https://10.0.2.10:6443";  # TODO: Update IP after master setup
    # tokenFile = config.sops.secrets.k3s-token.path;  # Enable after SOPS setup
    # Or set token directly: token = "YOUR_TOKEN_HERE";
    extraFlags = toString [
      "--node-label=node.kubernetes.io/arch=arm64"
      "--node-label=node.kubernetes.io/type=raspberry-pi"
    ];
  };
}
