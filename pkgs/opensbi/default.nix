{
  pkgs,
  stdenv,
  fetchFromGitHub,
}:

pkgs.opensbi.overrideAttrs (old: {
  src = fetchFromGitHub {
    owner = "revyos";
    repo = "thead-opensbi";
    rev = "f6e8831ac4d36faa32ab849b9d65353c714d2145";  # branch: lpi4a
    sha256 = "sha256-oWNygIoA5oFGEN4sj3CaFGt7zdI7hXzCOAI3qlfNGY8=";
  };
  makeFlags = pkgs.opensbi.makeFlags ++ ["FW_PIC=y"];
})
