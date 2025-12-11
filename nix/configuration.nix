# Raspberry Pi NixOS Configuration
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Boot
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Raspberry Pi hardware (headless - no GPU needed)
  boot.kernelPackages = pkgs.linuxPackages_rpi4;  # Pi-specific kernel

  # Hostname
  networking.hostName = "pi";

  # Network - DHCP
  networking.useDHCP = lib.mkDefault true;

  # WiFi support (connect with: iwctl)
  networking.wireless.iwd.enable = true;

  # User
  users.users.daniel = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIERVPDCkh+qmjc4hYecW+YDSdEDE0Z0A2UAguy8HScXT danielsteman@Daniels-MBP.localdomain"
    ];
  };

  # Passwordless sudo
  security.sudo.wheelNeedsPassword = false;

  # SSH
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # Root SSH access too
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIERVPDCkh+qmjc4hYecW+YDSdEDE0Z0A2UAguy8HScXT danielsteman@Daniels-MBP.localdomain"
  ];

  # Basic packages
  environment.systemPackages = with pkgs; [
    vim
    htop
    git
  ];

  # Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "24.05";
}
