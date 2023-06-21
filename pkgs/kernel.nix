# { lib, stdenv, buildLinux, src, ... } @ args:

# # args of buildLinux:
# #   https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/kernel/generic.nix
# # Note that this method will use the deconfig in source tree, 
# # commbined the common configuration defined in pkgs/os-specific/linux/kernel/common-config.nix, which is suitable for a NixOS system.
# # but it't not suitable for embedded systems, so we comment it out.
# 
# buildLinux (args // {
#   # check version in kernel source tree's Makefile
#   #   https://github.com/revyos/thead-kernel/blob/lpi4a/Makefile
#   version = "5.10.113";

#   # according to https://wiki.sipeed.com/hardware/zh/lichee/th1520/lpi4a/7_develop_revyos.html
#   # specify the deconfig(default kernel configuration) file located under:
#   #   https://github.com/revyos/thead-kernel/tree/lpi4a/arch/riscv/configs
#   defconfig = "light_defconfig";

#   structuredExtraConfig = with lib.kernel; lib.mkForce {
#     # MEDIA_DIGITAL_TV_SUPPORT = no;
#   };
# }) // (args.argsOverride or {})


# If you already have a generated configuration file, you can build a kernel that uses it with pkgs.linuxManualConfig
# The difference between deconfig and the generated configuration file is that the generated configuration file is more complete,
# 
{
  lib,
  src,
  stdenv,
  linuxManualConfig,
  ...
}:
(linuxManualConfig {
  version = "5.10.113-thead-1520";
  modDirVersion = "5.10.113";

  inherit src lib stdenv;
  
  # path to the generated kernel config file
  # 
  # you can generate the config file based on the light_defconfig 
  # by running `make light_defconfig` in the kernel source tree.
  # and then copy the generated file(`.config`) to ./light_config in the same directory of this file.
  # 
  #   make light_defconfig   # generate the config file from light_defconfig (the default config file)
  #   make menuconfig        # view and modify the generated config file(.config) via Terminal UI
  #                          # input / to search, Ctrl+Backspace to delete.
  configfile = ./light_config;

  extraMakeFlags = [
    # set the CFLAGS and CPPFLAGS to enable the rv64gc and lp64d.
    # as described here:
    #   https://github.com/graysky2/kernel_compiler_patch#alternative-way-to-define-a--march-option-without-this-patch

    # can not contain any space, otherwise it will report error
    # "KCFLAGS=-march=rv63gc -mabi=lp64d"
    # "KCPPFLAGS=-march=rv64gc -mabi=lp64d"
    "NIX_CFLAGS_COMPILE=-march=rv64gc"
    "KCFLAGS=-march=rv64gc"
    "KCPPFLAGS=-march=rv64gc"
  ];

  extraMeta.branch = "lp4a";

  allowImportFromDerivation = true;
})
