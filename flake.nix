{
  description = "NixOS running on LicheePi 4A";

  inputs = {
    # nixpkgs do not provide binary cache for riscv64-linux, we need to build everything from scratch anyway.
    # so we can use the small channel to get updates more quickly.
    #    checkout more details here: https://hydra.nixos.org/jobset/nixos/release-23.05#tabs-jobs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05-small";

    # according to https://github.com/sipeed/LicheePi4A/blob/pre-view/.gitmodules
    kernel-src = {
      url = "github:revyos/thead-kernel/lpi4a";
      flake = false;
    };
  };

  outputs = inputs@{ 
    self
    ,nixpkgs
    ,... }: 
  let
    pkgsKernel = import nixpkgs {
      localSystem = "x86_64-linux";
      crossSystem = {
        config = "riscv64-unknown-linux-gnu";

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
      };
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
            system = "riscv64-linux";
          };
        }

        ./modules/licheepi4a.nix
      ];
    };

    devShells.x86_64-linux.default = let
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
            pkgconfig
            ncurses
            pkgsKernel.gccStdenv.cc
          ]
          ++ pkgs.linux.nativeBuildInputs);
        runScript = pkgs.writeScript "init.sh" ''
          export toolchain_tripe=riscv64-unknown-linux-gnu-
          export ARCH=riscv
          export hardeningDisable=all
          export PKG_CONFIG_PATH="${pkgs.ncurses.dev}/lib/pkgconfig:"
          exec bash
        '';
      }).env;
  };
}
