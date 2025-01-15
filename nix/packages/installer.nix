{
  pkgs,
  system ? "x86_64-linux",
}:
(pkgs.lib.nixosSystem {
  inherit system;
  #specialArgs = inputs;
  modules = [ ../systems/installer.nix ];
}).config.system.build.isoImage
