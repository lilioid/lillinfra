{ pkgs, flake }:
let
  # packages which are autodetected from this directory
  dirContent = (builtins.readDir ./.);
  dirNonDefault = pkgs.lib.filterAttrs
    (iName: iValue: iName != "default.nix")
    dirContent;
  dirPkgs = pkgs.lib.mapAttrs'
    (iName: iValue: {
      name = (pkgs.lib.removeSuffix ".nix" iName);
      value = pkgs.callPackage ./${iName} { };
    })
    dirNonDefault;

  # manually defined packages or overrides from existing nixpkgs packages
  manualPkgs = {
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

    # a k3s package that applies my custom patch to use my custom flannel version
    k3s-custom =
      let
        overrides = {
          patches = [ ./k3s.patch ];
          vendorHash = "sha256-SctFg2GQSspQjg6ViTwCiqufitaylfN6jpukzqQ2W6s=";
        };
        k3s_def = flake.inputs.nixpkgs + "/pkgs/applications/networking/cluster/k3s";
        k3s_all = (pkgs.callPackage k3s_def {
          overrideBundleAttrs = overrides;
        });
        k3s = k3s_all.k3s_1_32.overrideAttrs overrides;
      in
      k3s;

    # pull in signal from nixos-unstable because the current signal binary fails in its build
    signal-desktop =
      let
        pkgs-unstable = import flake.inputs.nixpkgs-unstable { system = pkgs.system; };
      in
      pkgs-unstable.signal-desktop;
  };
in
pkgs.lib.mergeAttrs dirPkgs manualPkgs
