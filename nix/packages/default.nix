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

  # a ready-to-use version of pkgs pulled from nixos-unstable
  pkgs-unstable = import flake.inputs.nixpkgs-unstable { system = pkgs.system; };

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

    # overwrite certain programs from nixos-unstable because of newer versions
    
    # build keepass with patch that fixes evolution compatibility
    # https://github.com/keepassxreboot/keepassxc/pull/13532
    keepassxc = pkgs-unstable.keepassxc.overrideAttrs (finalAttrs: previousAttrs: {
      patches = previousAttrs.patches ++ [
        (pkgs-unstable.fetchurl {
          url = "https://github.com/keepassxreboot/keepassxc/pull/13532.patch";
          hash = "sha256-TgVCGsuqQQTfSc1gZaojzxg9PA1CLjTFFhN5Z5kjKms=";
        })
      ];
    });

    # glab = pkgs-unstable.glab;
  };
in
pkgs.lib.mergeAttrs dirPkgs manualPkgs
