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
            # https://nixos.wiki/wiki/Build_flags
            # this option equals to add `-march=rv64gc` into CFLAGS.
            # 
            # A little more detail; 
            # RISC-V is a modular ISA, meaning that it only has a mandatory base, 
            # and everything else is an extension. 
            # RV64GC is basically "RISC-V 64-bit, extensions G and C":
            # 
            #  G: Shorthand for the IMAFDZicsr_Zifencei base and extensions
            #  C: Standard Extension for Compressed Instructions 
            # 
            # for more details about the shorthand of RISC-V's extension, see:
            #   https://en.wikipedia.org/wiki/RISC-V#Design
            # 
            # LicheePi 4A is a high-performance development board which supports extension G and C.
            # we need to enable them to get revyos's kernel built.
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
