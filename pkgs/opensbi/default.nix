{
  pkgs,
  stdenv,
  fetchFromGitHub,
}:

# Using the prebuilt firmware temporarily.
stdenv.mkDerivation {
  pname = "thead-opensbi";
  version = "unstable-2023-08-06";

  src = ./fw_dynamic.bin;

  buildCommand = ''
    install -Dm444 $src $out/share/opensbi/lp64/generic/firmware/fw_dynamic.bin 
  '';
}

# Build OpenSBI from source.
# Currently failed with error:
#        last 10 log lines:
#        > /build/source/lib/utils/libfdt/fdt_wip.c:55: undefined reference to `__stack_chk_fail'
#        > /nix/store/sik6wrw04rlll76ab55f36wi1vi4kmic-riscv64-unknown-linux-gnu-binutils-2.40/bin/riscv64-unknown-linux-gnu-ld: /build/source/build/platform/generic/lib/libplatsbi.a
# (fdt_wip.o): in function `fdt_nop_property':
#        > /build/source/lib/utils/libfdt/fdt_wip.c:71: undefined reference to `__stack_chk_guard'
#        > /nix/store/sik6wrw04rlll76ab55f36wi1vi4kmic-riscv64-unknown-linux-gnu-binutils-2.40/bin/riscv64-unknown-linux-gnu-ld: /build/source/build/platform/generic/lib/libplatsbi.a
# (fdt_wip.o): in function `fdt_node_end_offset_':
#        > /build/source/lib/utils/libfdt/fdt_wip.c:78: undefined reference to `__stack_chk_fail'
#        > /nix/store/sik6wrw04rlll76ab55f36wi1vi4kmic-riscv64-unknown-linux-gnu-binutils-2.40/bin/riscv64-unknown-linux-gnu-ld: /build/source/lib/utils/libfdt/fdt_wip.c:81: undefine
# d reference to `__stack_chk_guard'
#        > /nix/store/sik6wrw04rlll76ab55f36wi1vi4kmic-riscv64-unknown-linux-gnu-binutils-2.40/bin/riscv64-unknown-linux-gnu-ld: /build/source/build/platform/generic/lib/libplatsbi.a
# (fdt_wip.o): in function `fdt_nop_region_':
#        > /build/source/lib/utils/libfdt/fdt_wip.c:55: undefined reference to `__stack_chk_fail'
#        > collect2: error: ld returned 1 exit status
#        > make: *** [Makefile:358: /build/source/build/platform/generic/firmware/fw_dynamic.elf] Error 1
#        For full logs, run 'nix log /nix/store/x12gq0y029w719l23vhzj20336qxq0y3-opensbi-riscv64-unknown-linux-gnu-1.2.drv'.
# 
# https://github.com/NixOS/nixpkgs/blob/32deda9ec08f550e4e0ece7708c4b674b2ca0dda/pkgs/misc/opensbi/default.nix#L11
# https://github.com/chainsx/fedora-riscv-builder/blob/20230623-0255/build.sh
# pkgs.opensbi.overrideAttrs (old: {
#   src = fetchFromGitHub {
#     owner = "revyos";
#     repo = "thead-opensbi";
#     rev = "lpi4a";
#     sha256 = "sha256-MgOlxvo2spe/TJHUbyymy5W/zJq6CLdf4iuyQRVNeU4=";
#     # sha256 = "";
#   };
#   makeFlags = pkgs.opensbi.makeFlags ++ ["FW_PIC=y"];
# })
