{
  description = "NixOS running on LicheePi 4A";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    # g: general purpose: IMAFD_Zicsr_Zifencei
    # c: compressed instruction
    # v: vector
    # we cannot use v extension, as gcc13 support v0.11, gcc 14 support v1.0, but C910 is v0.7
    gcc-march = "rv64gc" # "v" is not enabled
              ;
    # lp64d: long, pointers are 64-bit. GPRs, 64-bit FPRs, and the stack are used for parameter passing.
    gcc-mabi = "lp64d";

    qemu-cpu = "rv64,g=true,c=true" # ",v=true" is not enabled
             ;

    crossSystemConfig = {
      config = "riscv64-unknown-linux-gnu";
      gcc.arch = gcc-march;
      gcc.abi = gcc-mabi;
    };

    overlay = final: prev: {
      light_aon_fpga = final.callPackage ./pkgs/firmware/light_aon_fpga.nix {};
      light_c906_audio = final.callPackage ./pkgs/firmware/light_c906_audio.nix {};
      linux_thead = final.callPackage ./pkgs/linux {};
      linuxPackages_thead = final.linuxPackagesFor final.linux_thead;
      thead-opensbi = final.callPackage ./pkgs/opensbi {};
    };

    pkgsHost = import nixpkgs {
      localSystem = "x86_64-linux";
    };

    pkgsKernelCross = import nixpkgs {
      localSystem = "x86_64-linux";
      crossSystem = crossSystemConfig;
      overlays = [ overlay ];
    };

    pkgsKernelNative = import nixpkgs {
      localSystem = crossSystemConfig;
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
          nixpkgs.crossSystem = crossSystemConfig;
          nixpkgs.overlays = [
          ];
        }

        ./modules/licheepi4a.nix
        ./modules/sd-image/sd-image-lp4a.nix
        ./modules/user-group.nix
      ];
    };

    packages.x86_64-linux = {
      linux = pkgsKernelCross.linux_thead;
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
            pkg-config
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
          export KCFLAGS=' -march=${gcc-march} -mabi=${gcc-mabi}'
          export KCPPFLAGS=' -march=${gcc-march} -mabi=${gcc-mabi}'

          exec bash
        '';
      })
      .env;
  };
}
