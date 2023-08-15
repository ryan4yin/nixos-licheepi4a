# Deployment

> WIP, use at your own risk.

The sdImage built from this flake lacks configuration & cache for compilation.
Consequently, if you intend to execute an application not present within the sdImage, such as `nix run nixpkgs#cowsay hello`, nix will try to build `cowsay` and all its dependencies from scratch. This can take a long time!

To avoid this, you can deploy your configuration remotely on a high performance machine, this can be done with [colmena](https://github.com/zhaofengli/colmena).

If you're not familiar with remote deployment, please read this tutorial first: [Remote Deployment - NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/best-practices/remote-deployment)

## Deploying remotely with colmena

First, create a file `flake.nix` with the following content:

```nix
{
  description = "NixOS configuration for licheepi4a";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05-small";
    nixos-licheepi4a.url = "github:ryan4yin/nixos-licheepi4a";
  };

  outputs = { self, nixpkgs, nixos-licheepi4a }: let
    system = "x86_64-linux";
  in {
    colmena = {
      meta = {
        nixpkgs = import nixpkgs { inherit system; };
        specialArgs = {
          inherit nixpkgs;
          pkgsKernel = nixos-licheepi4a.packages.${system}.pkgsKernelCross;
        };
      };

      lp4a = { name, nodes, ... }: {
        deployment.targetHost = "192.168.5.42";
        deployment.targetUser = "root";

        imports = [
          {
            # cross-compilation this flake.
            nixpkgs.crossSystem = {
              system = "riscv64-linux";
            };
          }

          # import the licheepi4a module, which contains the configuration for bootloader/kernel/firmware
          (nixos-licheepi4a + "/modules/licheepi4a.nix")
          # import the sd-image module, which contains the fileSystems & kernel parameters for booting from sd card.
          (nixos-licheepi4a + "/modules/sd-image/sd-image-lp4a.nix")

          # your custom configuration
          ./configuration.nix
          ./user-group.nix
        ];
      };
    };
  };
}
```

Then create `configuration.nix` which contains your custom configuration:

```nix
{config, pkgs, ...}: {

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
}
```

And your `user-group.nix`:

```nix
let
  # TODO Customize your username & hostname.
  username = "lp4a";
  hostName = "lp4a";

  # To generate a hashed password run `mkpasswd`.
  # this is the hash of the password "lp4a"
  hashedPassword = "$y$j9T$mTIe/80yqh53danHYbUkP1$2TYCUsFKnkBnHG6pArOv9t.e2ofxO.j1MIt/6rB05P1";
  # TODO replace this with your own public key!
  publickey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK3F3AH/vKnA2vxl72h67fcxhIK8l+7F/bdE1zmtwTVU ryan@romantic";
in {
  # =========================================================================
  #      Users & Groups NixOS Configuration
  # =========================================================================

  networking.hostName = hostname;

  # TODO Define a user account. Don't forget to update this!
  users.users."${username}" = {
    inherit hashedPassword;

    isNormalUser = true;
    home = "/home/${username}";
    extraGroups = ["users" "networkmanager" "wheel" "docker"];
    openssh.authorizedKeys.keys = [
      publickey
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    publickey
  ];

  users.groups = {
    "${username}" = {};
    docker = {};
  };
}
```

Now you can deploy your configuration to the device:

```bash
nix run nixpkgs#colmena apply 
```


