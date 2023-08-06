let
  username = "lp4a";
in
{
  # =========================================================================
  #      Users & Groups NixOS Configuration
  # =========================================================================

  # TODO Define a user account. Don't forget to update this!
  users.users."${username}" = {
    # To generate a hashed password run `mkpasswd`.
    # this is the hash of the password "lp4a"
    hashedPassword = "$y$j9T$mTIe/80yqh53danHYbUkP1$2TYCUsFKnkBnHG6pArOv9t.e2ofxO.j1MIt/6rB05P1";
    isNormalUser = true;
    home = "/home/${username}";
    description = "nixos for licheepi4a";
    extraGroups = [ "users" "networkmanager" "wheel" "docker"];
    openssh.authorizedKeys.keys = [
        # TODO replace this with your own public key!
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL7hMSL3g0AGEofxFHWHAcg5FQT/YPkB7T+f2vuVVe91 ryan@gluttony"
    ];
  };

  users.groups = {
    "${username}" = {};
    docker = {};
  };

  # DO NOT promote user to input password for sudo.
  # this is a workaround for the issue of remote deploy:
  #   https://github.com/NixOS/nixpkgs/issues/118655
  #
  # Feel free to remove this if you don't need it.
  security.sudo.extraRules = [
    {
      users = [ username ];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}
