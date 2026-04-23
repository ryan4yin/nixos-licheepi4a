{
  buildLinux,
  fetchFromGitHub,
  lib,
  linuxKernel,
  ...
}:

buildLinux rec {
  pname = "linux-th1520";
  version = "7.0.0";
  modDirVersion = version;

  src = fetchFromGitHub {
    owner = "revyos";
    repo = "linux";
    rev = "5541c6584179d180aa921ef2f3c01d063e965b11"; # revyos/7.0.y on 2026-04-22
    sha256 = "sha256-1zyDp9Tgc06TMhMucNTiJq9XSzPHWxrJbCE5YriB9QA=";
  };

  defconfig = "debian_defconfig";

  kernelPatches = with linuxKernel.kernelPatches; [
    bridge_stp_helper
    request_key_helper
  ];

  extraMeta = {
    branch = "revyos/7.0.y";
    platforms = [ "riscv64-linux" ];
  };
}
