# Shared k3s node configuration
# Used by both Pi (ARM) and NUC VMs (x86)
{ config, pkgs, lib, ... }:

{
  # ─────────────────────────────────────────────────────────────────
  # K3s Configuration
  # ─────────────────────────────────────────────────────────────────

  # Default to agent - override in host config for master
  services.k3s = {
    enable = true;
    role = "agent";
    # serverAddr and tokenFile set per-host
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

  # K8s tools
  environment.systemPackages = with pkgs; [
    k9s
    kubectl
  ];
}
