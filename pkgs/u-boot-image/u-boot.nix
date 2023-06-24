
{ lib, buildUBoot, fetchFromGitHub, opensbi }: buildUBoot rec {
  version = "2023.06.25";
  
  # https://github.com/chainsx/fedora-riscv-builder/blob/20230623-0255/build.sh#L120-L128
  src = fetchFromGitHub {
    # owner = "revyos";
    # repo = "thead-u-boot";
    # rev = "lpi4a";

    # a custom kernel that supports reading /boot/extlinux/extlinux.conf
    owner = "chainsx";
    repo = "thead-u-boot";
    rev = "dev";
    sha256 = "";
  };

  defconfig = "light_lpi4a_defconfig";

  extraMeta.platforms = [ "riscv64-linux" ];
  extraMakeFlags = [
    "OPENSBI=${opensbi}/share/opensbi/lp64/generic/firmware/fw_dynamic.bin"
  ];

  filesToInstall = [ "spl/u-boot-with-spl.bin" ];
}