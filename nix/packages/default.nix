{ pkgs, self }:
{
  show-wg-conf = pkgs.callPackage ./show-wg-conf { };
  hetzner-ddns = pkgs.callPackage ./hetzner-ddns.nix { };
  installer = self.outputs.nixosConfigurations.installer.config.system.build.isoImage;
  show-nixos-diff = pkgs.callPackage ./show-nixos-diff { };

  # the kustomize-sops package installs itself as a library by default but we need it to be an executable in PATH
  kustomize-sops = pkgs.kustomize-sops.overrideAttrs (
    final: prev: {
      installPhase = ''
        mkdir -p $out/bin/
        mv $GOPATH/bin/kustomize-sops $out/bin/ksops
      '';
      meta = prev.meta // {
        mainProgram = "ksops";
      };
    }
  );

}
