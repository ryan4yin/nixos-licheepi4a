{ lib, pkgs, pkgsKernel, ... }: 

{

# =========================================================================
#      Board specific configuration
# =========================================================================

  imports = [
    ./base.nix
    ./hardware.nix
  ];

  boot = {
    loader.grub.enable = false;
    loader.generic-extlinux-compatible.enable = true;
    kernelPackages = pkgsKernel.linuxPackages_thead;

    # https://github.com/chainsx/fedora-riscv-builder/blob/51841d872b/config/config-emmc.txt
    kernelParams = [
      "console=ttyS0,115200"
      "root=/dev/mmcblk0p2"  # use the second partition of the eMMC as rootfs
      "rootfstype=ext4"
      "rootwait"
      "rw"
      "earlycon"
      "clk_ignore_unused"
      "loglevel=7"
      "eth=$ethaddr"
      "rootrwoptions=rw,noatime"
      "rootrwreset=yes"
    ];
    
    initrd.includeDefaultModules = false;
    initrd.availableKernelModules = lib.mkForce [
      "ext4" "sd_mod" "mmc_block" "spi_nor"
      "xhci_hcd"
      "usbhid" "hid_generic"
    ];
  };

  systemd.services."serial-getty@hvc0" = {
    enable = false;
  };


  # Some filesystems (e.g. zfs) have some trouble with cross (or with BSP kernels?) here.
  boot.supportedFilesystems = lib.mkForce [
    "vfat"
    "ext4"
    "btrfs"
  ];

  # allow missing modules, only enable this for testing!
  # nixpkgs.overlays = [
  #   (_: super: {makeModulesClosure = x: super.makeModulesClosure (x // {allowMissing = true;});})
  # ];

  environment.systemPackages = with pkgs; [
    mtdutils
  ];

}
