{ inputs }:
let
  mkSystem =
    systemType: name: nixpkgs:
    nixpkgs.lib.nixosSystem {
      system = builtins.replaceStrings [ "-unknown-" "-gnu" ] [ "-" "" ] systemType;
      specialArgs = inputs;
      modules = [
        inputs.disko.nixosModules.disko
        inputs.home-manager.nixosModules.home-manager
        inputs.sops-nix.nixosModules.default
        inputs.lix.nixosModules.lixFromNixpkgs

        ../modules/base_system.nix
        ../modules/user_lilly.nix
        ../modules/dev_env.nix
        ../modules/gnome.nix
        ../modules/backup.nix
        ../modules/syncthing.nix
        ./${name}.nix

        (
          let
            fqdnParts = nixpkgs.lib.strings.splitString "." name;
          in
          {
            networking.hostName = builtins.head fqdnParts;
            networking.domain =
              if ((builtins.length fqdnParts) > 1) then
                (builtins.concatStringsSep "." (builtins.tail fqdnParts))
              else
                null;
          }
        )
      ];
    };
in
{
  # exposed hosts at myroot
  "hosting.srv.ftsell.de" =
    mkSystem "x86_64-unknown-linux-gnu" "hosting.srv.ftsell.de"
      inputs.nixpkgs2411-small;
  "rt-hosting.srv.ftsell.de" =
    mkSystem "x86_64-unknown-linux-gnu" "rt-hosting.srv.ftsell.de"
      inputs.nixpkgs2411-small;
  "mail.srv.ftsell.de" = mkSystem "x86_64-unknown-linux-gnu" "mail.srv.ftsell.de" inputs.nixpkgs2411;
  "gtw.srv.ftsell.de" =
    mkSystem "x86_64-unknown-linux-gnu" "gtw.srv.ftsell.de"
      inputs.nixpkgs2411-small;

  # internal hosts at myroot
  "k8s-ctl.srv.myroot.intern" =
    mkSystem "x86_64-unknown-linux-gnu" "k8s-ctl.srv.myroot.intern"
      inputs.nixpkgs2411-small;
  "k8s-worker1.srv.myroot.intern" =
    mkSystem "x86_64-unknown-linux-gnu" "k8s-worker1.srv.myroot.intern"
      inputs.nixpkgs2411-small;
  "vpn.srv.myroot.intern" =
    mkSystem "x86_64-unknown-linux-gnu" "vpn.srv.myroot.intern"
      inputs.nixpkgs2411-small;
  "nas.srv.myroot.intern" =
    mkSystem "x86_64-unknown-linux-gnu" "nas.srv.myroot.intern"
      inputs.nixpkgs2411-small;

  # servers at home
  "priv.srv.home.intern" =
    mkSystem "aarch64-unknown-linux-gnu" "priv.srv.home.intern"
      inputs.nixpkgs2405-small;
  "proxy.srv.home.intern" =
    mkSystem "aarch64-unknown-linux-gnu" "proxy.srv.home.intern"
      inputs.nixpkgs2405-small;

  # private systems
  lillysLaptop = mkSystem "x86_64-unknown-linux-gnu" "lillysLaptop" inputs.nixpkgs2411;

  # home systems
  "finnsWorkstation.home.intern" =
    mkSystem "x86_64-unknown-linux-gnu" "finnsWorkstation"
      inputs.nixpkgs2411;

  # others
  "factorio.z9.ccchh.net" =
    mkSystem "x86_64-unknown-linux-gnu" "factorio.z9.ccchh.net"
      inputs.nixpkgs2405;
  "lan-server.intern" = mkSystem "x86_64-unknown-linux-gnu" "lan-server.intern" inputs.nixpkgs2405;
}
