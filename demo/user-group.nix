# Default account: Unix user `user`, password lp4a (see README.md).
# Public key below is a valid-format placeholder; the private key is not in this repo — replace
# with your own `ssh-ed25519` line (from ~/.ssh/id_ed25519.pub or similar) before relying on SSH keys.
# To generate a new hashed password: `mkpasswd`.

let
  username = "user";
  hostname = "licheepi4a";
  hashedPassword = "$y$j9T$mTIe/80yqh53danHYbUkP1$2TYCUsFKnkBnHG6pArOv9t.e2ofxO.j1MIt/6rB05P1";
  # Placeholder only (no matching private key shipped here).
  publickey = "ssh-ed25519 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX demo-placeholder-replace-me";
in
{
  networking.hostName = hostname;

  users.users."${username}" = {
    inherit hashedPassword;

    isNormalUser = true;
    home = "/home/${username}";
    extraGroups = [
      "users"
      "networkmanager"
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      publickey
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    publickey
  ];
}
