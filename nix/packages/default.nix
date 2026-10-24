{ pkgs, flake }:
let
  # packages which are autodetected from this directory
  dirContent = (builtins.readDir ./.);
  dirNonDefault = pkgs.lib.filterAttrs (iName: iValue: iName != "default.nix") dirContent;
  dirPkgs = pkgs.lib.mapAttrs' (iName: iValue: {
    name = (pkgs.lib.removeSuffix ".nix" iName);
    value = pkgs.callPackage ./${iName} { };
  }) dirNonDefault;

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
    # glab = pkgs-unstable.glab;

    # override icingaweb2 packages to build current versions
    icingaweb2 = pkgs.icingaweb2.overrideAttrs (
      finalAttrs: prevAttrs: {
        version = "2.14.0";
        src = pkgs.fetchFromGitHub {
          owner = "Icinga";
          repo = "icingaweb2";
          rev = "v${finalAttrs.version}";
          hash = "sha256-GpRVd6ArkNRqy+CJppZmtUtFedbhXDphE0H6JFuvDlQ=";
        };
        patches = [
          ./0001-Fix-static-files-not-being-servable-if-library-is-in.patch
          ./0002-fix-library-JS-not-being-included-under-symlinked-li.patch
        ];
      }
    );
    icingaweb2-ipl = pkgs.icingaweb2-ipl.overrideAttrs (
      finalAttrs: prevAttrs: {
        version = "1.0.1";
        src = pkgs.fetchFromGitHub {
          owner = "Icinga";
          repo = "icinga-php-library";
          rev = "v${finalAttrs.version}";
          hash = "sha256-gv82/hFW0yg7bXiTCRHZ765XsViahJCyV8HU/VyyV6Q=";
        };
      }
    );
    icingaweb2-thirdparty = pkgs.icingaweb2-thirdparty.overrideAttrs (
      finalAttrs: prevAttrs: {
        version = "1.0.1";
        src = pkgs.fetchFromGitHub {
          owner = "Icinga";
          repo = "icinga-php-thirdparty";
          rev = "v${finalAttrs.version}";
          hash = "sha256-1oTJC/hWMTx4gij1nbSJAzwZQFcA/xCb9Kh2WGC8SEQ=";
        };
      }
    );
    icingaweb2Modules.icingadb-web = pkgs.stdenv.mkDerivation (finalAttrs: {
      pname = "icingadb-web";
      version = "1.4.0";

      src = pkgs.fetchFromGitHub {
        owner = "Icinga";
        repo = finalAttrs.pname;
        tag = "v${finalAttrs.version}";
        sha256 = "sha256-2OSk1ppduExGXJre03WPa0Wf2+6Di9kxUwXx3Rh7uFo=";
      };

      installPhase = ''
        mkdir -p "$out"
        cp -r * "$out"
      '';

      meta = {
        description = "Icinga DB Web – UI for Icinga DB – Provides a graphical interface to your Icinga monitoring";
        homepage = "https://github.com/Icinga/icingadb-web";
        sourceProvenance = pkgs.lib.sourceTypes.fromSource;
        license = pkgs.lib.licenses.gpl3;
        platforms = pkgs.lib.platforms.all;
        maintainers = with pkgs.lib.maintainers; [ lilioid ];
      };
    });

    # currently does not work because integration tests for pass fail
    # gnupg = pkgs.callPackage
    #   (flake.inputs.nixpkgs + "/pkgs/by-name/se/sequoia-chameleon-gnupg/package.nix")
    #   { gnupg = pkgs.gnupg; };
  };
in
pkgs.lib.mergeAttrs dirPkgs manualPkgs
