# Simple flake for Raspberry Pi
{
  description = "NixOS Raspberry Pi";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.pi = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        ./configuration.nix
      ];
    };

    # Build with: nix build .#sdImage
    packages.aarch64-linux.sdImage =
      self.nixosConfigurations.pi.config.system.build.sdImage;

    packages.aarch64-linux.default =
      self.nixosConfigurations.pi.config.system.build.sdImage;
  };
}
