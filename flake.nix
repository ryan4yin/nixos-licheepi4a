{
  description = "NixOS running on LicheePi 4A";

  inputs = {
    # nixpkgs do not provide binary cache for riscv64-linux, we need to build everything from scratch anyway.
    # so we can use the small channel to get updates more quickly.
    #    checkout more details here: https://hydra.nixos.org/jobset/nixos/release-23.05#tabs-jobs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05-small";

    # according to https://github.com/sipeed/LicheePi4A/blob/pre-view/.gitmodules
    thead-kernel = {
      url = "github:revyos/thead-kernel/lpi4a";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    thead-kernel,
    ...
  }: let
    buildFeatures = {
      config = "riscv64-unknown-linux-gnu";

      # https://nixos.wiki/wiki/Build_flags
      # this option equals to add `-march=rv64gc` into CFLAGS.
      # CFLAGS will be used as the command line arguments for the gcc/clang.
      #
      # Note: CFLAGS is not used by the kernel build system! so this would not work for the kernel build.
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
      # Note: CFLAGS is not used by the kernel build system! so this would not work for the kernel build.
      #
      # lp64d: long, pointers are 64-bit. GPRs, 64-bit FPRs, and the stack are used for parameter passing.
      #
      # related docs:
      #  https://github.com/riscv-non-isa/riscv-toolchain-conventions/blob/master/README.mkd#specifying-the-target-abi-with--mabi
      gcc.abi = "lp64d";
    };
    overlay = self: super: {
      linuxPackages_thead = super.linuxPackagesFor (super.callPackage ./pkgs/kernel {
        src = thead-kernel;
        stdenv = super.gcc13Stdenv;
        kernelPatches = with super.kernelPatches; [
          bridge_stp_helper
          request_key_helper
        ];
      });

      light_aon_fpga = super.callPackage ./pkgs/firmware/light_aon_fpga.nix { };
      light_c906_audio = super.callPackage ./pkgs/firmware/light_c906_audio.nix { };
      thead-opensbi = super.callPackage ./pkgs/opensbi { };
    };
    pkgsKernelCross = import nixpkgs {
      localSystem = "x86_64-linux";
      crossSystem = buildFeatures;

      overlays = [ overlay ];
    };
    pkgsKernelNative = import nixpkgs {
      localSystem = buildFeatures;

      overlays = [ overlay ];
  };
  in {
    # expose this flake's overlay
    overlays.default = overlay;

    # cross-build an sd-image
    nixosConfigurations.lp4a-cross = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      specialArgs = {
        inherit nixpkgs;
        pkgsKernel = pkgsKernelCross;
      };
      modules = [
        {
          # cross-compilation this flake.
          nixpkgs.crossSystem = {
            system = "riscv64-linux";
          };
        }

        ./modules/licheepi4a.nix
        ./modules/sd-image/sd-image-lp4a.nix
        ./modules/user-group.nix
      ];
    };

    packages.x86_64-linux = {
      # u-boot & sdImage for boot from sdcard.
      uboot = pkgsKernelCross.callPackage ./pkgs/u-boot {};
      sdImage = self.nixosConfigurations.lp4a-cross.config.system.build.sdImage;

      # the nixpkgs
      pkgsKernelCross = pkgsKernelCross;
      pkgsKernelNative = pkgsKernelNative;
    };

    # use `nix develop .#fhsEnv` to enter the fhs test environment defined here.
    devShells.x86_64-linux.fhsEnv = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
      };
    in
      # the code here is mainly copied from:
      #   https://nixos.wiki/wiki/Linux_kernel#Embedded_Linux_Cross-compile_xconfig_and_menuconfig
      (pkgs.buildFHSUserEnv {
        name = "kernel-build-env";
        targetPkgs = pkgs_: (with pkgs_;
          [
            # we need theses packages to run `make menuconfig` successfully.
            pkgconfig
            ncurses

            pkgsKernelCross.gcc13Stdenv.cc
            gcc
          ]
          ++ pkgs.linux.nativeBuildInputs);
        runScript = pkgs.writeScript "init.sh" ''
          # set the cross-compilation environment variables.
          export CROSS_COMPILE=riscv64-unknown-linux-gnu-
          export ARCH=riscv
          export PKG_CONFIG_PATH="${pkgs.ncurses.dev}/lib/pkgconfig:"

          # set the CFLAGS and CPPFLAGS to enable the rv64gc and lp64d.
          # as described here:
          #   https://github.com/graysky2/kernel_compiler_patch#alternative-way-to-define-a--march-option-without-this-patch
          export KCFLAGS=' -march=rv64gc -mabi=lp64d'
          export KCPPFLAGS=' -march=rv64gc -mabi=lp64d'

          exec bash
        '';
      })
      .env;
  };
}
