{config, pkgs, ...}: {
# =========================================================================
#      Common NixOS Configuration
# =========================================================================

  # enable flakes globally
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git      # used by nix flakes
    wget
    curl
    aria2
    lm_sensors  # for `sensors` command

    neofetch
    ranger # terminal file manager
    btop     # replacement of htop/nmon
    iotop
    iftop

    # # archives
    zip
    xz
    unzip
    p7zip
    zstd
    file
    which
    tree
    gnused
    gnutar
    gawk

    # misc
    docker-compose
  ];

  # replace default editor with neovim
  environment.variables.EDITOR = "vim";

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true;
      PermitRootLogin = "no";         # disable root login
      PasswordAuthentication = false; # disable password login
    };
    openFirewall = true;
  };

  virtualisation.docker.enable = true;

  users.groups = {
    ryan = {};
    docker = {};
  };

  # TODO Define a user account. Don't forget to update this!
  users.users.lp4a = {
    # To generate a hashed password run `mkpasswd`.
    # this is the hash of the password "lp4a"
    hashedPassword = "$y$j9T$mTIe/80yqh53danHYbUkP1$2TYCUsFKnkBnHG6pArOv9t.e2ofxO.j1MIt/6rB05P1";
    isNormalUser = true;
    home = "/home/lp4a";
    description = "nixos for licheepi4a";
    extraGroups = [ "users" "networkmanager" "wheel" "docker"];
    openssh.authorizedKeys.keys = [
        # TODO replace this with your own public key!
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL7hMSL3g0AGEofxFHWHAcg5FQT/YPkB7T+f2vuVVe91 ryan@gluttony"
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
