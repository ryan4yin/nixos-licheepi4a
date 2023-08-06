{config, pkgs, nixpkgs, ...}: {

  # =========================================================================
  #      Base NixOS Configuration
  # =========================================================================

  nix.settings = {
    # Manual optimise storage: nix-store --optimise
    # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
    auto-optimise-store = true;
    builders-use-substitutes = true;
    # enable flakes globally
    experimental-features = ["nix-command" "flakes"];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # make `nix run nixpkgs#nixpkgs` use the same nixpkgs as the one used by this flake.
  nix.registry.nixpkgs.flake = nixpkgs;
  # make `nix repl '<nixpkgs>'` use the same nixpkgs as the one used by this flake.
  environment.etc."nix/inputs/nixpkgs".source = "${nixpkgs}";
  nix.nixPath = ["/etc/nix/inputs"];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git      # used by nix flakes
    wget
    curl
    aria2

    # system
    neofetch
    lm_sensors  # `sensors`
    ranger # terminal file manager
    btop     # replacement of htop/nmon
    iotop
    iftop

    # system call monitoring
    strace
    lsof

    mtr      # A network diagnostic tool
    iperf3   # A tool for measuring TCP and UDP bandwidth performance
    nmap     # A utility for network discovery and security auditing
    ldns     # replacement of dig, it provide the command `drill`
    socat    # replacement of openbsd-netcat
    tcpdump  # A powerful command-line packet analyzer

    # archives
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
    tmux

    # python, some times I may need to use python with root permission.
    (python310.withPackages (ps:
      with ps; [
        ipython
        requests
        pyquery
        pyyaml

        numpy
        opencv4
      ]
    ))
  ];

  # replace default editor with neovim
  environment.variables.EDITOR = "vim";

  networking = {
    hostName = "lp4a";

    # defaultGateway = "192.168.5.201";
    # nameservers = [
    #   "119.29.29.29" # DNSPod
    #   "223.5.5.5" # AliDNS
    # ];

    # interfaces.enp5s0 = {
    #   useDHCP = false;
    #   ipv4.addresses = [
    #     {
    #       address = "192.168.5.103";
    #       prefixLength = 24;
    #     }
    #   ];
    # };
  };

  # replacement of networkmanger
  # https://wiki.archlinux.org/title/ConnMan
  services.connman = {
    enable = true;
    package = (pkgs.connman.override {
      enableVpnc = false;  # failed to build on riscv64
      enableOpenvpn = false;
      enablePptp = false;
    });
    enableVPN = false;
  };


  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true;
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false; # disable password login
    };
    openFirewall = true;
  };

  virtualisation.docker = {
    enable = true;
    # start dockerd on boot.
    # This is required for containers which are created with the `--restart=always` flag to work.
    enableOnBoot = true;
  };

  # PipeWire is a new low-level multimedia framework.
  # It aims to offer capture and playback for both audio and video with minimal latency.
  # It support for PulseAudio-, JACK-, ALSA- and GStreamer-based applications.
  # PipeWire has a great bluetooth support, it can be a good alternative to PulseAudio.
  #     https://nixos.wiki/wiki/PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };
  # rtkit is optional but recommended
  security.rtkit.enable = true;
  # Remove sound.enable or turn it off if you had it set previously, it seems to cause conflicts with pipewire
  sound.enable = false;
  # Disable pulseaudio, it conflicts with pipewire too.
  hardware.pulseaudio.enable = false;

  # enable bluetooth & gui paring tools - blueman
  # or you can use cli:
  # $ bluetoothctl
  # [bluetooth] # power on
  # [bluetooth] # agent on
  # [bluetooth] # default-agent
  # [bluetooth] # scan on
  # ...put device in pairing mode and wait [hex-address] to appear here...
  # [bluetooth] # pair [hex-address]
  # [bluetooth] # connect [hex-address]
  # Bluetooth devices automatically connect with bluetoothctl as well:
  # [bluetooth] # trust [hex-address]
  hardware.bluetooth.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
