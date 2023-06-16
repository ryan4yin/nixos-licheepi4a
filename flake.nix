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
    # cross-build
    nixosConfigurations.lp4a-cross = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";

      specialArgs = inputs // {
        pkgs-gcc11 = import nixpkgs {
          system = system;
          overlays = [ (self: super: { gcc = self.gcc11; }) ];
        };
      };
      modules = [
        {
          # cross-compilation this flake.
          nixpkgs.crossSystem = {
            # https://nixos.wiki/wiki/Build_flags
            # this option equals to add `-march=rv64gc` into CFLAGS.
            # CFLAGS will be used as the command line arguments for the gcc/clang.
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
            # the same as `-mabi=lp64d` in CFLAGS.
            # 
            # lp64d: long, pointers are 64-bit. GPRs, 64-bit FPRs, and the stack are used for parameter passing.
            # 
            # related docs:
            #  https://github.com/riscv-non-isa/riscv-toolchain-conventions/blob/master/README.mkd#specifying-the-target-abi-with--mabi
            gcc.abi = "lp64d";

            system = "riscv64-linux";
          };
        }

        ./modules/licheepi4a.nix
      ];
    };

    # emulated-build or native-build
    # 
    # NOTE: build using qemu-based emulated system is really slow...
    #      it may takes about 5 hours to build the rootfs on R9-5900HX.
    nixosConfigurations.lp4a-emulated = nixpkgs.lib.nixosSystem rec {
      system = "riscv64-linux";

      specialArgs = inputs;
      modules = [
        {
          nixpkgs.localSystem = {
            # add flags to gcc: `-march=rv64gc -mabi=lp64d`
            gcc.arch = "rv64gc";
            gcc.abi = "lp64d";

            system = system;
          };
        }
        ./modules/licheepi4a.nix
      ];
    };
  };
}
