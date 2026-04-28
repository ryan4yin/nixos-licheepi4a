{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
}:
stdenvNoCC.mkDerivation {
  pname = "powervr-rogue";
  version = "2026.04.15";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "imagination";
    repo = "linux-firmware";
    rev = "8a58f81883f7be458daa34e418cc4079f995b279"; # powervr on 2026-04-15
    sparseCheckout = [
      "/powervr/*"
      "/LICENSE"
      "/LICENSE.powervr"
      "/WHENCE"
    ];
    nonConeMode = true;
    hash = "sha256-3Tkc3Y5JD57V1eJ9hBqIAsCb28ZYb7sXdVrDN8omTYE=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm444 -t $out/lib/firmware/powervr $src/powervr/*.fw
    install -Dm444 $src/LICENSE $out/share/licenses/powervr-rogue-firmware/LICENSE
    install -Dm444 $src/LICENSE.powervr $out/share/licenses/powervr-rogue-firmware/LICENSE.powervr
    install -Dm444 $src/WHENCE $out/share/licenses/powervr-rogue-firmware/WHENCE

    runHook postInstall
  '';

  meta = {
    description = "Firmware for Imagination PowerVR Rogue GPUs";
    homepage = "https://gitlab.freedesktop.org/imagination/linux-firmware/-/tree/powervr/powervr";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = lib.platforms.linux;
  };
}
