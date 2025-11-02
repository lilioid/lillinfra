{
  description = "lillinfra - lillys infrastructure configuration";

  nixConfig = {
    extra-substituters = [ "https://babe-do-you-need-anything-from-the-nix.store/lillinfra" ];
    extra-trusted-public-keys = [ "lillinfra:1oor1T8FgQ3DwH0Y0altYYU/+ZRa3oBb1zGhltxPu1Y=" ];
  };

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    nixpkgs-small.url = "github:nixos/nixpkgs?ref=nixos-25.05-small";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # version-specific nixpkgs
    nixpkgs2411.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    nixpkgs2505.url = "github:nixos/nixpkgs?ref=nixos-25.05";

    # some helpers for writing flakes with less repetition
    systems.url = "github:nix-systems/default-linux";

    # support for special hardware quirks
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # dotfile (and user package) manager
    home-manager = {
      url = "github:nix-community/home-manager?ref=release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # disk partitioning description
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # secret management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # more output formats for nixos images
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # lix package manager
    # https://lix.systems
    lix = {
      url = "git+https://git.lix.systems/lix-project/nixos-module.git?ref=release-2.93";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # treeformat for specifying how to properly format files in this repo
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # lanzaboot for secure-boot on nixos
    # https://github.com/nix-community/lanzaboote
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # cookied (not yet merged in nixpkgs)
    cookied = {
      url = "git+https://codeberg.org/lilly/cookied.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      systems,
      treefmt-nix,
      cookied,
      ...
    }:
    let
      # instantiate nixpkgs for the given system, configuring this flake's overlay too
      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          overlays = [
            self.overlays.default
            cookied.overlays.default
          ];
        };
      # helper to iterate over all supported systems, passing the corresponding nixpkgs set
      eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f (mkPkgs system));
      # evaluate the treefmt.nix module given an instantiated nixpkgs
      treefmtEval = pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
    in
    {
      nixosConfigurations = import ./nix/systems { flake = self; };
      overlays.default =
        final: prev:
        import ./nix/packages {
          flake = self;
          pkgs = prev;
        };
      packages = eachSystem (pkgs: import ./nix/packages { inherit pkgs; flake = self; });

      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            fluxcd
            kubectl
            kustomize
            kubernetes-helm
            jq
            cmctl
            age
            ssh-to-age
            woodpecker-cli
            python311
            python311Packages.pynetbox
            python311Packages.ipython
            pre-commit
            show-wg-conf
            show-nixos-diff
            kustomize-sops
            opentofu
          ];
        };
      });

      # maintenance
      formatter = eachSystem (pkgs: (treefmtEval pkgs).config.build.wrapper);
      checks = eachSystem (pkgs: {
        formatting = (treefmtEval pkgs).config.build.check self;
      });
    };
}
