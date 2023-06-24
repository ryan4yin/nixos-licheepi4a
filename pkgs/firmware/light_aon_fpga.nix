{
  stdenv,
  fetchurl,
}:
stdenv.mkDerivation {
  pname = "light_aon_fpga-firmware";
  version = "unstable-2023-06-25";

  src = fetchurl {
    url = "https://github.com/chainsx/fedora-riscv-builder/raw/20230623-0255/firmware/light_aon_fpga.bin";
    hash = "sha256-cIFaWDbiX0nNzlhkhhKapjGeN64dblFE1DxZh01kV5s=";
  };

  buildCommand = ''
    install -Dm444 $src $out/lib/firmware/light_aon_fpga.bin
  '';
}
