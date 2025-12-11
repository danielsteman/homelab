# Raspberry Pi NixOS Configuration
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Boot
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible = {
    enable = true;
    device = "nodev";
  };

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
    k9s
    kubectl
  ];

  # ─────────────────────────────────────────────────────────────────
  # K3s Configuration
  # ─────────────────────────────────────────────────────────────────

  # K3s agent (worker node)
  # TODO: Update serverAddr after k3s-master is set up
  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://k3s-master:6443";  # Will update with actual IP
    # tokenFile = "/run/secrets/k3s-token";  # Use SOPS secret later
  };

  # Firewall - k3s ports
  networking.firewall = {
    allowedTCPPorts = [
      22     # SSH
      6443   # Kubernetes API (if master)
      10250  # Kubelet
    ];
    allowedUDPPorts = [
      8472   # Flannel VXLAN
    ];
    # Allow cluster network traffic
    trustedInterfaces = [ "cni0" "flannel.1" ];
  };

  # Kernel settings for k8s
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "24.05";
}
