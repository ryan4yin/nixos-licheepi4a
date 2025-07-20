# NOTE: make sure to update your password and public key in this file
# NOTE: to generate a hashed password, you can use the `mkpasswd` command.

let
  username = "user";
  hostname = "licheepi4a";
  # default password is "lp4a"
  hashedPassword = "$y$j9T$mTIe/80yqh53danHYbUkP1$2TYCUsFKnkBnHG6pArOv9t.e2ofxO.j1MIt/6rB05P1";
  # default public key is my own, change it to your own public key!
  publickey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGfKhCawAW4dQz5OtDGZIlKvuNx3+Iovw5X/251Wfxnq user@dev";
in {
  networking.hostName = hostname;

  users.users."${username}" = {
    inherit hashedPassword;

    isNormalUser = true;
    home = "/home/${username}";
    extraGroups = ["users" "networkmanager" "wheel" "docker"];
    openssh.authorizedKeys.keys = [
      publickey
    ];
  };

  # also add public key to root user
  users.users.root.openssh.authorizedKeys.keys = [
    publickey
  ];
}
