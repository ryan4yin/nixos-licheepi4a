
{ lib, buildUBoot, fetchFromGitHub, thead-opensbi }:

(buildUBoot rec {
  version = "2025.11.24";

  src = fetchFromGitHub {
    # https://github.com/revyos/thead-u-boot
    owner = "revyos";
    repo = "thead-u-boot";
    rev = "0028a957e3684e6ed2a1f446034191b5120fd3ec"; # th1520 tag 20251124
    sha256 = "sha256-FLnVSSgI2GtJBTn1WOZLLAJ2PtckAUhdVY9zzl5pf30=";
  };

  defconfig = "light_lpi4a_defconfig";

  extraMeta.platforms = [ "riscv64-linux" ];
  extraMakeFlags = [
    "OPENSBI=${thead-opensbi}/share/opensbi/lp64/generic/firmware/fw_dynamic.bin"
  ];

  filesToInstall = [ "u-boot-with-spl.bin" ];
}).overrideAttrs (oldAttrs: {
  patches = [
    ./patches/0001-feat-use-mmcbootpart-1-for-nixos.patch
  ];
})
