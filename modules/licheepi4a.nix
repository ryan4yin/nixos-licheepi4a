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
    kernelPackages = pkgsKernel.linuxPackages_thead;
    
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
