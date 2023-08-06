
{ lib, buildUBoot, fetchFromGitHub, thead-opensbi }: 

(buildUBoot rec {
  version = "2023.08.06";
  
  src = fetchFromGitHub {
    # https://github.com/revyos/thead-u-boot
    owner = "revyos";
    repo = "thead-u-boot";
    rev = "lpi4a";
    sha256 = "sha256-SEaaCFJo7v7AJNVaH9JGrUXX+c9gRkKvRXEdjzUQEtI=";

    # a custom kernel that supports reading /boot/extlinux/extlinux.conf
    # https://github.com/chainsx/fedora-riscv-builder/blob/20230623-0255/build.sh#L120-L128
    # owner = "chainsx";
    # repo = "thead-u-boot";
    # rev = "extlinux";
    # sha256 = "";
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
