# =================================================================================================
# function `buildLinux`:
#   https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/kernel/generic.nix
# Note that this method will use the deconfig in source tree, 
# commbined the common configuration defined in pkgs/os-specific/linux/kernel/common-config.nix, 
# it't not suitable for embedded systems, so we can NOT use it here.
# Instead, we need to use the method `linuxManualConfig` to build the kernel.
# =================================================================================================

# If you already have a generated configuration file, you can build a kernel that uses it with pkgs.linuxManualConfig
# The difference between deconfig and the generated configuration file is that the generated configuration file is more complete,
# 
{
  lib,
  src,
  stdenv,
  ubootTools,
  linuxManualConfig,
  ...
}:
(linuxManualConfig {
  version = "5.10.113-thead-1520";
  modDirVersion = "5.10.113";

  inherit src lib stdenv;
  
  # path to the generated kernel config file
  # 
  # you can generate the config file based on the revyos_defconfig 
  # by running `make revyos_defconfig` in the kernel source tree.
  # and then copy the generated file(`.config`) to ./revyos_config in the same directory of this file.
  # 
  #   make revyos_defconfig   # generate the config file from revyos_defconfig (the default config file)
  #   make menuconfig        # view and modify the generated config file(.config) via Terminal UI
  #                          # input / to search, Ctrl+Backspace to delete.
  #
  # and need to add these three lines to the end of the generated config file:
  #   CONFIG_DMIID=y
  #   CONFIG_VECTOR=n
  #   CONFIG_THEAD_ISA=n
  configfile = ./revyos_config;
  
  extraMeta.branch = "lp4a";

  allowImportFromDerivation = true;
}).overrideAttrs (old: {
  name = "k"; # shorten the kernel name, dodge uboot length limits, otherwise it will make uboot fail to load kernel. 
  nativeBuildInputs = old.nativeBuildInputs ++ [ubootTools];
})
