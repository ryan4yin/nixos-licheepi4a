{ config, pkgs, nixpkgs, ... }: {
 # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  nix.settings = {
    # Manual optimise storage: nix-store --optimise
    # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
    auto-optimise-store = true;
    builders-use-substitutes = true;
    # enable flakes globally
    experimental-features = [ "nix-command" "flakes" ];
  };

  # make `nix run nixpkgs#nixpkgs` use the same nixpkgs as the one used by this flake.
  nix.registry.nixpkgs.flake = nixpkgs;
  # make `nix repl '<nixpkgs>'` use the same nixpkgs as the one used by this flake.
  environment.etc."nix/inputs/nixpkgs".source = "${nixpkgs}";
  nix.nixPath = [ "/etc/nix/inputs" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # === system ===
    # utils
      zsh
      neofetch
      jq
      htop
      tree
      file
      hexyl
    # device
      pciutils
      usbutils
      minicom
      lm_sensors
      i2c-tools
    # archive
      zip unzip
      xz
      bzip2
      gzip
      zstd
    # network
      dnsutils
      ethtool
    # kernel
      kmod

    # === dev ===
    # version control
      git git-lfs
    # languages
      python3
    # openjdk # not support riscv64 now
      gcc
    # debug
      gdb
      pwntools
    # build tools
      gnumake
      autoconf
      automake
      cmake
  ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true;
      PasswordAuthentication = false;
    };
    openFirewall = true;
  };

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # Fix for vscode-server, etc.
  # programs.nix-ld.enable = true; # nix-ld 2.0.0+ does not support riscv64 now

  # Fix for /bin/xxx shebang
  # services.envfs.enable = true; # envfs does not support riscv64 now

  virtualisation.docker.enable = true;

  services.tailscale.enable = true;
}
