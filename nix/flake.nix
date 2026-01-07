# NixOS configurations for homelab
# Proxmox VMs (x86)
{
  description = "Homelab NixOS Configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-generators, ... }: {
    # ─────────────────────────────────────────────────────────────
    # Proxmox VMs (x86)
    # ─────────────────────────────────────────────────────────────
    # Template VM - minimal base for cloning
    nixosConfigurations.template = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/template.nix
      ];
    };

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
    # VM Image for Proxmox Template
    # ─────────────────────────────────────────────────────────────
    # Build raw disk image from template config using nixos-generators
    # Raw format can be converted to qcow2 for Proxmox
    # Note: Image building will be handled in CI/CD workflow
    # For now, this is a placeholder - we'll build images via GitHub Actions
    packages.x86_64-linux.vmImage =
      self.nixosConfigurations.template.config.system.build.toplevel;
  };
}
