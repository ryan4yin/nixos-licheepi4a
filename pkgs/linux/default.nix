{
  buildLinux,
  fetchFromGitHub,
  lib,
  linuxKernel,
  ...
}:

buildLinux rec {
  pname = "linux-th1520";
  version = "7.0.1";
  modDirVersion = version;

  src = fetchFromGitHub {
    owner = "revyos";
    repo = "linux";
    rev = "01805654d228b07b8d96ffa1ea6aca798c98d7dc"; # revyos/7.0.y on 2026-04-23
    sha256 = "sha256-6x+sfUh+f9ZFKN8kIu2+Mt09W1+RmqsGsSvOWGD4Bg4=";
  };

  defconfig = "debian_defconfig";

  kernelPatches = with linuxKernel.kernelPatches; [
    bridge_stp_helper
    request_key_helper
  ];

  structuredExtraConfig = with lib.kernel; {
    DRM_POWERVR = module;
  };

  extraMeta = {
    branch = "revyos/7.0.y";
    platforms = [ "riscv64-linux" ];
  };
}
