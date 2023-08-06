{ config, lib, modulesPath, pkgs, pkgsKernel, ... }: 

{

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

  fileSystems = lib.mkForce {
    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
      # Alternatively, this could be removed from the configuration.
      # The filesystem is not needed at runtime, it could be treated
      # as an opaque blob instead of a discrete FAT32 filesystem.
      options = [ "nofail" "noauto" ];
    };
    "/" = {
      device = "/dev/disk/by-label/root";
      fsType = "ext4";
    };
  };

  # https://github.com/NixOS/nixpkgs/blob/master/nixos/lib/make-ext4-fs.nix
  system.build = {
    rootfsImage = pkgs.callPackage "${modulesPath}/../lib/make-ext4-fs.nix" ({
      storePaths = [ config.system.build.toplevel ];
      compressImage = false;
      populateImageCommands = ''
        mkdir -p ./files/boot
      '';
      volumeLabel = "root";
    });
    bootImage = pkgs.callPackage "${modulesPath}/../lib/make-ext4-fs.nix" ({
      storePaths = [  ];
      compressImage = false;
      populateImageCommands = ''
        cp ${pkgsKernel.thead-opensbi}/share/opensbi/lp64/generic/firmware/fw_dynamic.bin ./files/fw_dynamic.bin
        cp ${pkgsKernel.light_aon_fpga}/lib/firmware/light_aon_fpga.bin ./files/light_aon_fpga.bin
        cp ${pkgsKernel.light_c906_audio}/lib/firmware/light_c906_audio.bin ./files/light_c906_audio.bin
        ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/

        rm -rf ./files/nix
      '';
      volumeLabel = "boot";
    });
  };
}
