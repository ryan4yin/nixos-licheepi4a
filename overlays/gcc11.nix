{ ... }:

(self: super: {
  # according to https://github.com/NixOS/nixpkgs/issues/235179#issuecomment-1571465764
  # revert the default gcc to 11
  gcc = self.gcc11; 
})
