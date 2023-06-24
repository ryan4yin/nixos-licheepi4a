{ config, modulesPath, ... }: {

  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
  ];

  sdImage = {
    # for local usage, do not need to compress it.
    # compressImage = false;
    populateFirmwareCommands = "";
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };

}