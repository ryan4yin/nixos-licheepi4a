{
  description = "NixOS configuration for licheepi4a remote deployment";

  # the nixConfig here only affects the flake itself, not the system configuration!
  # This is a cache server provided by me, feel free to remove it if you don't trust me.
  nixConfig = {
    substituters = [
      "https://licheepi4a.cachix.org"
    ];

    extra-trusted-public-keys = [
      "licheepi4a.cachix.org-1:oHyaY5wsuQ4+JjpZOQWTlxxd7c0fYfTjUCNCSP5gkJg="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05-small";
    nixos-licheepi4a.url = "github:ryan4yin/nixos-licheepi4a";
  };

  outputs = { self, nixpkgs, nixos-licheepi4a, ... } @ inputs: let
    system = "x86_64-linux";
  in {
    colmena = {
      meta = {
        # using the same nixpkgs as nixos-licheepi4a to utilize the cross-compilation cache.
        nixpkgs = import nixos-licheepi4a.inputs.nixpkgs { inherit system; };
        specialArgs = {
          pkgsKernel = nixos-licheepi4a.packages.${system}.pkgsKernelCross;
        } // inputs;
      };

      lp4a = { name, nodes, ... }: {
        # Set this ip to your licheepi4a board ip address.
        deployment.targetHost = "192.168.5.104";
        deployment.targetUser = "root";

        imports = [
          {
            # cross-compilation this flake.
            nixpkgs.crossSystem = {
              system = "riscv64-linux";
            };
          }

          # import the licheepi4a module, which contains the configuration for bootloader/kernel/firmware
          (nixos-licheepi4a + "/modules/licheepi4a.nix")
          # import the sd-image module, which contains the fileSystems & kernel parameters for booting from sd card.
          (nixos-licheepi4a + "/modules/sd-image/sd-image-lp4a.nix")

          # your custom configuration
          ./configuration.nix
          ./user-group.nix
        ];
      };
    };
  };
}

