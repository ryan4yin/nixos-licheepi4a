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
#        >  CC        lib/sbi/sbi_misaligned_ldst.o
#        >  CC        lib/sbi/sbi_platform.o
#        >  CC        lib/sbi/sbi_scratch.o
#        >  CC        lib/sbi/sbi_string.o
#        >  CC        lib/sbi/sbi_system.o
#        >  CC        lib/sbi/sbi_timer.o
#        >  CC        lib/sbi/sbi_tlb.o
#        > /build/source/lib/sbi/sbi_tlb.c: Assembler messages:
#        > /build/source/lib/sbi/sbi_tlb.c:187: Error: unrecognized opcode `fence.i', extension `zifencei' required
#        > make: *** [Makefile:339: /build/source/build/lib/sbi/sbi_tlb.o] Error 1
# 
# https://github.com/NixOS/nixpkgs/blob/32deda9ec08f550e4e0ece7708c4b674b2ca0dda/pkgs/misc/opensbi/default.nix#L11
# https://github.com/chainsx/fedora-riscv-builder/blob/20230623-0255/build.sh
# pkgs.opensbi.overrideAttrs (old: {
#   src = fetchFromGitHub {
#     owner = "revyos";
#     repo = "thead-opensbi";
#     rev = "lpi4a";
#     sha256 = "";
#   };
#   makeFlags = pkgs.opensbi.makeFlags ++ ["FW_PIC=y"];
# })
