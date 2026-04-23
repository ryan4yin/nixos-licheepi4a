{
  description = "NixOS configuration for licheepi4a remote deployment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-licheepi4a.url = "github:ngc7331/nixos-licheepi4a";
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
        deployment.targetHost = "licheepi4a";
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
