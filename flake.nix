{
  description = "NixOS running on LicheePi 4A";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";

    # according to https://github.com/sipeed/LicheePi4A/blob/pre-view/.gitmodules
    kernel-src = {
      url = "github:revyos/thead-kernel/lpi4a";
      flake = false;
    };

  };

  outputs = inputs@{ self, nixpkgs, ... }: 
  
  let
    pkgsKernel = import nixpkgs {
      localSystem = "x86_64-linux";
      crossSystem = {
        config = "riscv64-unknown-linux-gnu";
      };
      overlays = [
        (self: super: { gcc = super.gcc10; })
      ];
    };
  in
  {
    # cross-build
    nixosConfigurations.lp4a = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      specialArgs = inputs // { inherit pkgsKernel;};
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

    devShells.x86_64-linux.default = let
      pkgs = pkgsKernel;
    in
      (pkgsKernel.buildFHSUserEnv {
        name = "kernel-build-env";
        targetPkgs = pkgs_: (with pkgs_;
          [
            pkgconfig
            ncurses
            qt5.qtbase
            gcc
          ]
          ++ pkgsKernel.linux.nativeBuildInputs);
        runScript = pkgsKernel.writeScript "init.sh" ''
          export toolchain_tripe=riscv64-unknown-linux-gnu-
          export ARCH=riscv
          export nproc=20
          export hardeningDisable=all
          export PKG_CONFIG_PATH="${pkgs.ncurses.dev}/lib/pkgconfig:${pkgs.qt5.qtbase.dev}/lib/pkgconfig"
          export QT_QPA_PLATFORM_PLUGIN_PATH="${pkgs.qt5.qtbase.bin}/lib/qt-${pkgs.qt5.qtbase.version}/plugins"
          export QT_QPA_PLATFORMTHEME=qt5ct
          export CFLAGS="-march=rv64gc -mabi=lp64d"
          exec bash
        '';
      }).env;
  };
}
