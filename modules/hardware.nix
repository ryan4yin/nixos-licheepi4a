{ pkgs, ... }:

{

  powerManagement.cpuFreqGovernor = "ondemand";

  hardware = {
    deviceTree = {
      # https://github.com/revyos/thead-kernel/blob/lpi4a/arch/riscv/boot/dts/thead/light-lpi4a.dts
      # https://github.com/chainsx/fedora-riscv-builder/blob/51841d872b/config/config-emmc.txt
      name = "thead/light-lpi4a.dtb";
      overlays = [
        # custom deviceTree here
      ];
    };
    enableRedistributableFirmware = true;


    # TODO GPU driver
    opengl = {
      enable = false;
    };

    # firmwares
    firmware = [
      # TODO add GPU firmware
    ];
  };
}