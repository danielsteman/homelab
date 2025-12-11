# NixOS configurations for homelab
# Supports: Raspberry Pi (ARM) + Proxmox VMs (x86)
{
  description = "Homelab NixOS Configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs, ... }: {
    # ─────────────────────────────────────────────────────────────
    # Raspberry Pi (ARM)
    # ─────────────────────────────────────────────────────────────
    nixosConfigurations.pi-worker = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        ./hosts/pi-worker.nix
      ];
    };

    # ─────────────────────────────────────────────────────────────
    # Proxmox VMs (x86)
    # ─────────────────────────────────────────────────────────────
    nixosConfigurations.k3s-master = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/k3s-master.nix
      ];
    };

    nixosConfigurations.k3s-worker-1 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/k3s-worker-1.nix
      ];
    };

    nixosConfigurations.k3s-worker-2 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/k3s-worker-2.nix
      ];
    };

    # ─────────────────────────────────────────────────────────────
    # SD Image for Pi
    # ─────────────────────────────────────────────────────────────
    packages.aarch64-linux.sdImage =
      self.nixosConfigurations.pi-worker.config.system.build.sdImage;

    packages.aarch64-linux.default =
      self.nixosConfigurations.pi-worker.config.system.build.sdImage;
  };
}
