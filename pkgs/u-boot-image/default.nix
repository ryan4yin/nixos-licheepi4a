{ pkgs, buildPackages, runCommandNoCC }:

let
  uboot = pkgs.callPackage ./u-boot.nix;

# https://github.com/chainsx/fedora-riscv-builder/blob/20230623-0255/build.sh#L140-L210C2
in runCommandNoCC "uboot-spi-image.img" {
  nativeBuildInputs = with buildPackages; [
    gptfdisk util-linux
  ];
} ''
  # SPI Image
  fallocate -l 6M image.bin

  sgdisk -g --clear --set-alignment=1 \
    --new=1:40:2087 --change-name=1:spl --typecode=1:5b193300-fc78-40cd-8002-e86c45580b47 \
    --new=2:2088:10279 --change-name=2:uboot --typecode=2:2e54b353-1271-4842-806f-e436d6af6985 \
    --new=3:10280:10535 --change-name=3:env --typecode=3:3de21764-95bd-54bd-a5c3-4abe786f38a8 \
    image.bin

  dd if=${uboot}/u-boot-spl.bin of=image.bin bs=4096 seek=5 conv=notrunc
  dd if=${uboot}/u-boot.itb of=image.bin bs=4096 seek=261 conv=notrunc

  cp image.bin $out
''
