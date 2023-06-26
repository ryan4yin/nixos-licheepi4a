# method 1, use "${modulesPath}/installer/sd-card/sd-image.nix"
#  with this method, the generated image has only /boot and /nix/store... I don't know if it works.
#
{ config, modulesPath, pkgs, ... }: 
let
  light_aon_fpga = (pkgs.callPackage ../pkgs/firmware/light_aon_fpga.nix {});
  light_c906_audio = (pkgs.callPackage ../pkgs/firmware/light_c906_audio.nix {});
in {
  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/sd-card/sd-image.nix
  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
  ];

  # https://github.com/chainsx/fedora-riscv-builder/blob/f46ae18/build.sh#L179-L184
  boot.kernelParams = [
    "console=ttyS0,115200"
    "root=/dev/mmcblk0p3"  # use the third partition of the eMMC as rootfs, it's hardcoded in u-boot
    "rootfstype=ext4"
    "rootwait"
    "rw"
    "earlycon"
    "clk_ignore_unused"
    "eth=$ethaddr"       # do not know if this works
    "rootrwoptions=rw,noatime"
    "rootrwreset=yes"
  ];

  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = ["noatime"];
    };
  };

  sdImage = {
    imageBaseName = "nixos-licheepi4a-sd-image";
    # for local usage, do not need to compress it.
    compressImage = false;
    # install firmware into a separate partition: /boot/firmware
    populateFirmwareCommands = ''
      cp ${pkgs.opensbi}/share/opensbi/lp64/generic/firmware/fw_dynamic.bin firmware/fw_dynamic.bin
      cp ${light_aon_fpga}/lib/firmware/light_aon_fpga.bin firmware/light_aon_fpga.bin
      cp ${light_c906_audio}/lib/firmware/light_c906_audio.bin firmware/light_c906_audio.bin
    '';

    # generate /boot
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot

      cp ${pkgs.opensbi}/share/opensbi/lp64/generic/firmware/fw_dynamic.bin ./files/boot/fw_dynamic.bin
      cp ${light_aon_fpga}/lib/firmware/light_aon_fpga.bin ./files/boot/light_aon_fpga.bin
      cp ${light_c906_audio}/lib/firmware/light_c906_audio.bin ./files/boot/light_c906_audio.bin
    '';
  };
}


# method 2, use "${modulesPath}/../lib/make-disk-image.nix"
# with this method, the generated image has a basic fhs layout.
# BUT THIS METHOD DOES NOT WORK, some seabios releated error(it seems do not support riscv64)
#
# { config, lib, nixpkgs, modulesPath, pkgs, ... }: {

#   fileSystems = {
#     "/" = {
#       device = "/dev/disk/by-label/nixos";
#       fsType = "ext4";
#       options = ["noatime"];
#     };
#   };

#   # https://github.com/NixOS/nixpkgs/blob/master/nixos/lib/make-disk-image.nix
#   system.build.sdImage = import "${modulesPath}/../lib/make-disk-image.nix" {
#     inherit config lib;
#     # need to use the unmodified corss build system to build the image for riscv64
#     pkgs = import nixpkgs {
#       localSystem = "x86_64-linux";
#       corssSystem = "riscv64-linux";
#     };
#     name = "licheepi4a-sd-image";
#     copyChannel = false;
#     format = "raw";
#   };

# }