# Minimal NixOS template configuration for Proxmox VMs
# This is used to build a base template image that can be cloned
# Generic enough to be reused, but includes your base config
{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    ../modules/common.nix
  ];

  # Boot (Proxmox VM)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Generic hostname (will be overridden when cloned/deployed)
  networking.hostName = "nixos-template";

  # Network - use DHCP (no static IP for template)
  networking.useDHCP = false;
  networking.interfaces.ens18.useDHCP = true;  # Proxmox default NIC

  # No k3s, no specific services - just a clean base
  # Cloned VMs will get their specific configs via deploy_nixos

  # VM image settings
  virtualisation = {
    # Enable QEMU guest agent for Proxmox integration
    qemu.guestAgent.enable = true;
  };

  system.stateVersion = "24.05";
}
