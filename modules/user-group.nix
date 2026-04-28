# Default account: Unix user `user`, password lp4a (see README.md).
# Add SSH keys under users.users.<name>.openssh.authorizedKeys.keys if you want key login.
# To generate a new hashed password: `mkpasswd`.

let
  username = "user";
  hostname = "licheepi4a";
  hashedPassword = "$y$j9T$mTIe/80yqh53danHYbUkP1$2TYCUsFKnkBnHG6pArOv9t.e2ofxO.j1MIt/6rB05P1";
in {
  networking.hostName = hostname;

  users.users."${username}" = {
    inherit hashedPassword;

    isNormalUser = true;
    home = "/home/${username}";
    extraGroups = ["users" "networkmanager" "wheel" "docker"];
  };
}
