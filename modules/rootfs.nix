{ config, modulesPath, ... }: {

  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/sd-card/sd-image.nix
  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
  ];

  sdImage = {
    # for local usage, do not need to compress it.
    compressImage = false;
    populateFirmwareCommands = "";

    # generate /boot as a mount point.
    populateRootCommands = ''
      mkdir -p ./files/boot
      # ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };
}