{config, pkgs, nixpkgs, ...}: {

  # =========================================================================
  #      Base NixOS Configuration
  # =========================================================================

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
    experimental-features = ["nix-command" "flakes"];
  };

  # make `nix run nixpkgs#nixpkgs` use the same nixpkgs as the one used by this flake.
  nix.registry.nixpkgs.flake = nixpkgs;
  # make `nix repl '<nixpkgs>'` use the same nixpkgs as the one used by this flake.
  environment.etc."nix/inputs/nixpkgs".source = "${nixpkgs}";
  nix.nixPath = ["/etc/nix/inputs"];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  #
  # TODO feel free to add or remove packages here.
  environment.systemPackages = with pkgs; [
    neovim

    # networking
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
    gnutar

    # misc
    file
    which
    tree
    gnused
    gawk
    tmux
    docker-compose
  ];

  # replace default editor with neovim
  environment.variables.EDITOR = "nvim";

  virtualisation.docker = {
    enable = true;
    # start dockerd on boot.
    # This is required for containers which are created with the `--restart=always` flag to work.
    enableOnBoot = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true;
      PermitRootLogin = "prohibit-password";  # disable root login with password
      PasswordAuthentication = false; # disable password login
    };
    openFirewall = true;
  };

  # Set static IP address / gateway / DNS servers.
  networking = {
    wireless.enable = false;

    # Failed to enable firewall due to the following error:
    #   firewall-start[2300]: iptables: Failed to initialize nft: Protocol not supported
    firewall.enable = false;

    defaultGateway = "192.168.5.201";
    nameservers = [
      "119.29.29.29" # DNSPod
      "223.5.5.5" # AliDNS
    ];

    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # LPI4A's first ethernet interface
    interfaces.end0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.5.104";
          prefixLength = 24;
        }
      ];
    };
    # LPI4A's second ethernet interface
    # interfaces.end1 = {
    #   useDHCP = false;
    #   ipv4.addresses = [
    #     {
    #       address = "192.168.xx.xx";
    #       prefixLength = 24;
    #     }
    #   ];
    # };
  };
}
