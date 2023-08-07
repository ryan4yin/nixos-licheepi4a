
{ lib, buildUBoot, fetchFromGitHub, thead-opensbi }: 

(buildUBoot rec {
  version = "2023.08.06";
  
  src = fetchFromGitHub {
    # https://github.com/revyos/thead-u-boot
    # owner = "revyos";
    # repo = "thead-u-boot";
    # rev = "lpi4a";
    # sha256 = "";

    # A custom kernel that supports boot from SD card and extlinux
    # https://github.com/chainsx/thead-u-boot
    owner = "chainsx";
    repo = "thead-u-boot";
    rev = "6474d15cef280def002a5beadfdfe2aa06c8981a"; # branch - extlinux
    sha256 = "sha256-ZWn7pwdAq3FS7fcoN3RAlsnlA/6KJZm0E8X7EFXstRs=";
  };

  defconfig = "light_lpi4a_defconfig";

  extraMeta.platforms = [ "riscv64-linux" ];
  extraMakeFlags = [
    "OPENSBI=${thead-opensbi}/share/opensbi/lp64/generic/firmware/fw_dynamic.bin"
  ];

  filesToInstall = [ "u-boot-with-spl.bin" ];
}).overrideAttrs (oldAttrs: {
  patches = [];  # remove all patches, which is not compatible with thead-u-boot
})
