{ pkgs }:
{
  show-wg-conf = pkgs.callPackage ./show-wg-conf { };
  #installer = pkgs.callPackage ./installer.nix {};
  hetzner-ddns = pkgs.callPackage ./hetzner-ddns.nix { };
}
