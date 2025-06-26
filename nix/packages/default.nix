{ pkgs, flake }:
{
  show-wg-conf = pkgs.callPackage ./show-wg-conf { };
  hetzner-ddns = pkgs.callPackage ./hetzner-ddns.nix { };
  show-nixos-diff = pkgs.callPackage ./show-nixos-diff { };
  installer = flake.outputs.nixosConfigurations.installer.config.system.build.isoImage;

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

  # pull in signal from nixos-unstable because the current signal binary fails in its build
  signal-desktop = let
    pkgs-unstable = import flake.inputs.nixpkgs-unstable { system = pkgs.system; };
  in pkgs-unstable.signal-desktop;
}
