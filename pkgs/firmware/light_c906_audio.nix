{
  stdenv,
  fetchurl,
}:
stdenv.mkDerivation {
  pname = "light_c906_audio-firmware";
  version = "unstable-2023-06-25";

  src = fetchurl {
    url = "https://github.com/chainsx/fedora-riscv-builder/raw/20230623-0255/firmware/light_c906_audio.bin";
    hash = "sha256-hv9OQhc6cH7swqVrhPhIxgUsgH4JMiOjw+DRWcK9nNQ=";
  };

  buildCommand = ''
    install -Dm444 $src $out/lib/firmware/light_c906_audio.bin
  '';
}
