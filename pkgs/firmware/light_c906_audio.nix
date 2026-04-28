{
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation {
  pname = "light_c906_audio-firmware";
  version = "2025.05.10";

  src = fetchFromGitHub {
    owner = "revyos";
    repo = "th1520-boot-firmware";
    rev = "725756411ecc20f2c2dbc5ea6b8e5aacc6f83aad"; # master on 2025-05-10
    sha256 = "sha256-pXRdMdtqzB9ytWSqyINSsIZhymiMqZOv2Gvz6194jM0=";
  };

  buildCommand = ''
    install -Dm444 $src/addons/boot/light_c906_audio.bin $out/lib/firmware/light_c906_audio.bin
  '';
}
