{
  pkgs,
  stdenv,
  fetchFromGitHub,
}:

pkgs.opensbi.overrideAttrs (old: {
  # https://github.com/revyos/thead-opensbi
  src = fetchFromGitHub {
    owner = "revyos";
    repo = "thead-opensbi";
    rev = "61d7484c752a5e4c464d5dc18e21d9ac67fbbefa"; # lp4a on 2025.04.23
    sha256 = "sha256-ag1r9FzCo91v/jdXDc8ygS7a+8eSs2izWf+OMT5JmKw=";
  };
  makeFlags =
    pkgs.opensbi.makeFlags
    ++ [
      "FW_PIC=y"
      # RevyOS's OpenSBI fork predates GCC's newer default C standard on unstable.
      "platform-cflags-y=-std=gnu17"
    ];
})
