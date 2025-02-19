{ pkgs, self }:
{
  show-wg-conf = pkgs.callPackage ./show-wg-conf { };
  hetzner-ddns = pkgs.callPackage ./hetzner-ddns.nix { };
  installer = self.outputs.nixosConfigurations.installer.config.system.build.isoImage;
  show-nixos-diff = pkgs.callPackage ./show-nixos-diff { };
  harmonia-oci = pkgs.callPackage ./harmonia-oci.nix { harmonia = self.inputs.harmonia; };
  openssh-oci = pkgs.callPackage ./openssh-oci.nix { };
}
