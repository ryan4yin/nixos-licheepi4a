{
  lib,
  pkgs,
  pkgsKernel,
  ...
}:
{
  boot = {
    kernelPackages = pkgsKernel.linuxPackages_thead;

    initrd.includeDefaultModules = false;
    initrd.availableKernelModules = lib.mkForce [
      "ext4"
      "sd_mod"
      "mmc_block"
      "spi_nor"
      "xhci_hcd"
      "usbhid"
      "hid_generic"
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

  powerManagement.cpuFreqGovernor = "ondemand";
  hardware = {
    deviceTree = {
      # https://github.com/revyos/thead-kernel/blob/lpi4a/arch/riscv/boot/dts/thead/light-lpi4a.dts
      # https://github.com/chainsx/fedora-riscv-builder/blob/51841d872b/config/config-emmc.txt
      name = "thead/th1520-lichee-pi-4a.dtb";
      overlays = [
        # custom deviceTree here
      ];
    };
    enableRedistributableFirmware = true;

    graphics = {
      enable = true;
    };

    firmware = [
      pkgsKernel.light_aon_fpga
      pkgsKernel.light_c906_audio
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

  # =========================================================================
  #      Base NixOS Configuration
  # =========================================================================

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # === system ===
    # utils
    fastfetch
    htop
    # device
    minicom
    lm_sensors
    i2c-tools
    # network
    dnsutils
    ethtool
    # kernel
    kmod

    # === dev ===
    # version control
    git
    # languages
    python3
    # openjdk # not support riscv64 now
    gcc
  ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      X11Forwarding = lib.mkDefault true;
      PasswordAuthentication = lib.mkDefault true;
    };
    openFirewall = lib.mkDefault true;
  };

  # Fix for vscode-server, etc.
  # programs.nix-ld.enable = lib.mkDefault true; # nix-ld 2.0.0+ does not support riscv64 now

  # Fix for /bin/xxx shebang
  # services.envfs.enable = lib.mkDefault true; # envfs does not support riscv64 now
}
