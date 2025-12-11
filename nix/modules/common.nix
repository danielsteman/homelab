# Common configuration for all nodes
{ config, pkgs, lib, ... }:

{
  # User
  users.users.daniel = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
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
    settings.PasswordAuthentication = false;
  };

  # Root SSH access
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIERVPDCkh+qmjc4hYecW+YDSdEDE0Z0A2UAguy8HScXT danielsteman@Daniels-MBP.localdomain"
  ];

  # Basic packages
  environment.systemPackages = with pkgs; [
    vim
    htop
    git
    curl
  ];

  # Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "daniel" ];

  system.stateVersion = "24.05";
}
