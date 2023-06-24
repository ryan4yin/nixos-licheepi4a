{ lib, pkgs, pkgsKernel, ... }: 

{

# =========================================================================
#      Board specific configuration
# =========================================================================

  imports = [
    ./base.nix
    ./rootfs.nix
  ];

  boot = {
    loader.grub.enable = false;
    loader.generic-extlinux-compatible.enable = true;
    kernelPackages = pkgsKernel.linuxPackages_thead;

    # https://github.com/chainsx/fedora-riscv-builder/blob/51841d872b/config/config-emmc.txt
    kernelParams = [
      "console=ttyS0,115200"
      "root=/dev/mmcblk0p3"  # use the third partition of the eMMC as rootfs
      "rootfstype=ext4"
      "rootwait"
      "rw"
      "earlycon"
      "clk_ignore_unused"
      "loglevel=7"
      "eth=$ethaddr"
      "rootrwoptions=rw,noatime"
      "rootrwreset=yes"
      "init=/lib/systemd/systemd"
    ];
    
    initrd.includeDefaultModules = false;
    initrd.availableKernelModules = lib.mkForce [
      "ext4" "sd_mod" "mmc_block" "spi_nor"
      "xhci_hcd"
      "usbhid" "hid_generic"
    ];
  };

  # https://github.com/revyos/thead-kernel/blob/lpi4a/arch/riscv/boot/dts/thead/light-lpi4a.dts
  # https://github.com/chainsx/fedora-riscv-builder/blob/51841d872b/config/config-emmc.txt
  hardware.deviceTree.name = "thead/light-lpi4a.dtb";

  systemd.services."serial-getty@hvc0" = {
    enable = false;
  };


  # Some filesystems (e.g. zfs) have some trouble with cross (or with BSP kernels?) here.
  boot.supportedFilesystems = lib.mkForce [
    "vfat"
    "ext4"
    "btrfs"
  ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = ["noatime"];
    };
  };

  # allow missing modules, only enable this for testing!
  # nixpkgs.overlays = [
  #   (_: super: {makeModulesClosure = x: super.makeModulesClosure (x // {allowMissing = true;});})
  # ];

  hardware.enableRedistributableFirmware = true;
  powerManagement.cpuFreqGovernor = "ondemand";

  environment.systemPackages = with pkgs; [
    mtdutils
  ];

}
