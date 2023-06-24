{ config, modulesPath, pkgs, ... }: 

let
  light_aon_fpga = (pkgs.callPackage ../pkgs/firmware/light_aon_fpga.nix {});
  light_c906_audio = (pkgs.callPackage ../pkgs/firmware/light_c906_audio.nix {});
in {
  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/sd-card/sd-image.nix
  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
  ];

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
    populateFirmwareCommands = '''';

    # generate /boot
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot

      cp ${pkgs.opensbi}/share/opensbi/lp64/generic/firmware/fw_dynamic.bin ./files/boot
      cp ${light_aon_fpga}/lib/firmware/light_aon_fpga.bin ./files/boot
      cp ${light_c906_audio}/lib/firmware/light_c906_audio.bin ./files/boot
    '';
  };
}