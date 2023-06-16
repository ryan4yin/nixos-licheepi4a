{
  description = "NixOS running on LicheePi 4A";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # according to https://github.com/sipeed/LicheePi4A/blob/pre-view/.gitmodules
    kernel-src = {
      url = "github:revyos/thead-kernel/lpi4a";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }: {
    nixosConfigurations.lp4a = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      specialArgs = inputs;
      modules = [
        {
          # cross-compilation this flake.
          nixpkgs.crossSystem = {
            gcc.arch = "rv64gc";
            config = "riscv64-unknown-linux-gnu";
            system = "riscv64-linux";
          };
        }

        ./modules/licheepi4a.nix
      ];
    };
  };
}
