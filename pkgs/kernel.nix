{ lib, stdenv, buildLinux, src, ... } @ args:

# args of buildLinux:
#   https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/kernel/generic.nix
buildLinux (args // {
  # check version in kernel source tree's Makefile
  #   https://github.com/revyos/thead-kernel/blob/lpi4a/Makefile
  version = "5.10.113";

  # according to https://wiki.sipeed.com/hardware/zh/lichee/th1520/lpi4a/7_develop_revyos.html
  defconfig = "light_config";

  structuredExtraConfig = with lib.kernel; lib.mkForce {
    MEDIA_DIGITAL_TV_SUPPORT = no;
  };
}) // (args.argsOverride or {})


# {
#   lib,
#   src,
#   linuxManualConfig,
#   ubootTools,
#   ...
# }:
# (linuxManualConfig {
#   version = "5.10.113-thead-1520";
#   modDirVersion = "5.10.113";

#   inherit src;
  
#   # path to the kernel config file
#   configfile = ./light_config;

#   extraMeta.branch = "lp4a";

#   allowImportFromDerivation = true;
# })
