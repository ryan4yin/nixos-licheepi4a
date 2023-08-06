#
{ config, lib, modulesPath, pkgs, pkgsKernel, ... }: 
let
  rootPartitionUUID = "14e19a7b-0ae0-484d-9d54-43bd6fdc20c7";
in {
  imports = [
    ./sd-image.nix
  ];

  # https://github.com/chainsx/fedora-riscv-builder/blob/f46ae18/build.sh#L179-L184
  boot.kernelParams = [
    "console=ttyS0,115200"
    "root=UUID=${rootPartitionUUID}"  # use the third partition of the eMMC as rootfs, it's hardcoded in u-boot
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

  fileSystems = lib.mkForce {
    "/boot" = {
      device = "/dev/disk/by-label/${config.sdImage.firmwarePartitionName}";
      fsType = "vfat";
      # Alternatively, this could be removed from the configuration.
      # The filesystem is not needed at runtime, it could be treated
      # as an opaque blob instead of a discrete FAT32 filesystem.
      options = [ "nofail" "noauto" ];
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };

  sdImage = {
    inherit rootPartitionUUID;

    imageBaseName = "nixos-licheepi4a-sd-image";
    # for local usage, do not need to compress it.
    compressImage = false;
    # install firmware into a separate partition: /boot/firmware
    populateFirmwareCommands = ''
      cp ${pkgsKernel.thead-opensbi}/share/opensbi/lp64/generic/firmware/fw_dynamic.bin firmware/fw_dynamic.bin
      cp ${pkgsKernel.light_aon_fpga}/lib/firmware/light_aon_fpga.bin firmware/light_aon_fpga.bin
      cp ${pkgsKernel.light_c906_audio}/lib/firmware/light_c906_audio.bin firmware/light_c906_audio.bin

      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./firmware
    '';
    firmwarePartitionName = "BOOT";
    firmwareSize = 200; # MiB

    populateRootCommands = ''
      mkdir -p ./files/boot
    '';
  };
}
