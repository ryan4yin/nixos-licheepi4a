{ config, modulesPath, pkgs, ... }: 

{
  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/sd-card/sd-image.nix
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-riscv64-qemu.nix"
  ];

  sdImage = {
    imageBaseName = "nixos-qemu-sd-image";
    # for local usage, do not need to compress it.
    compressImage = false;
    populateFirmwareCommands = '''';

    # generate /boot
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };
}