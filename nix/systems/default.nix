{ self, inputs }:
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
        ../modules/auto_upgrade.nix
        ../modules/mail_relay.nix
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
      inputs.nixpkgs2411;
  "rt-hosting.srv.ftsell.de" =
    mkSystem "x86_64-unknown-linux-gnu" "rt-hosting.srv.ftsell.de"
      inputs.nixpkgs2411;
  "mail.srv.ftsell.de" = mkSystem "x86_64-unknown-linux-gnu" "mail.srv.ftsell.de" inputs.nixpkgs2411;
  "gtw.srv.ftsell.de" =
    mkSystem "x86_64-unknown-linux-gnu" "gtw.srv.ftsell.de"
      inputs.nixpkgs2411;

  # internal hosts at myroot
  "k8s-ctl.srv.myroot.intern" =
    mkSystem "x86_64-unknown-linux-gnu" "k8s-ctl.srv.myroot.intern"
      inputs.nixpkgs2411;
  "k8s-worker1.srv.myroot.intern" =
    mkSystem "x86_64-unknown-linux-gnu" "k8s-worker1.srv.myroot.intern"
      inputs.nixpkgs2411;
  "vpn.srv.myroot.intern" =
    mkSystem "x86_64-unknown-linux-gnu" "vpn.srv.myroot.intern"
      inputs.nixpkgs2411;
  "nas.srv.myroot.intern" =
    mkSystem "x86_64-unknown-linux-gnu" "nas.srv.myroot.intern"
      inputs.nixpkgs2411;

  # servers at home
  "priv.srv.home.intern" =
    mkSystem "aarch64-unknown-linux-gnu" "priv.srv.home.intern"
      inputs.nixpkgs2411;
  "proxy.srv.home.intern" =
    mkSystem "aarch64-unknown-linux-gnu" "proxy.srv.home.intern"
      inputs.nixpkgs2411;

  # private systems
  lillysLaptop = mkSystem "x86_64-unknown-linux-gnu" "lillysLaptop" inputs.nixpkgs2411;

  # home systems
  "lillysWorkstation" =
    mkSystem "x86_64-unknown-linux-gnu" "lillysWorkstation"
      inputs.nixpkgs2411;

  # others
  "factorio.z9.ccchh.net" =
    mkSystem "x86_64-unknown-linux-gnu" "factorio.z9.ccchh.net"
      inputs.nixpkgs2405;
  "lan-server.intern" = mkSystem "x86_64-unknown-linux-gnu" "lan-server.intern" inputs.nixpkgs2405;
}
