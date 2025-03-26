{ flake }:
let
  mkSystem =
    systemType: name: nixpkgs:
    let
      lib = nixpkgs.lib;
      systemModule = if lib.pathIsDirectory ./${name} then ./${name}/system.nix else ./${name}.nix;
    in
    nixpkgs.lib.nixosSystem {
      specialArgs = flake.inputs;
      modules = [
        flake.inputs.disko.nixosModules.disko
        flake.inputs.home-manager.nixosModules.home-manager
        flake.inputs.sops-nix.nixosModules.default
        flake.inputs.lix.nixosModules.lixFromNixpkgs
        flake.inputs.cookied.nixosModules.default

        ../modules/base_system.nix
        ../modules/user_lilly.nix
        ../modules/dev_env.nix
        ../modules/gnome.nix
        ../modules/backup.nix
        ../modules/syncthing.nix
        ../modules/auto_upgrade.nix
        ../modules/mail_relay.nix
        systemModule

        (
          let
            fqdnParts = nixpkgs.lib.strings.splitString "." name;
          in
          {
            # nixpkgs settings based on function inputs
            nixpkgs.hostPlatform = systemType;
            nixpkgs.overlays = [
              flake.outputs.overlays.default
              flake.inputs.cookied.overlays.default
            ];

            # set hostname based on function inputs
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
  "hosting.srv.lly.sh" = mkSystem "x86_64-linux" "hosting.srv.lly.sh" flake.inputs.nixpkgs2411;
  "rt-hosting.srv.lly.sh" = mkSystem "x86_64-linux" "rt-hosting.srv.lly.sh" flake.inputs.nixpkgs2411;
  "mail.srv.lly.sh" = mkSystem "x86_64-linux" "mail.srv.lly.sh" flake.inputs.nixpkgs2411;
  "gtw.srv.lly.sh" = mkSystem "x86_64-linux" "gtw.srv.lly.sh" flake.inputs.nixpkgs2411;

  # internal hosts at myroot
  "k8s-ctl.srv.myroot.intern" =
    mkSystem "x86_64-linux" "k8s-ctl.srv.myroot.intern"
      flake.inputs.nixpkgs2411;
  "k8s-worker1.srv.myroot.intern" =
    mkSystem "x86_64-linux" "k8s-worker1.srv.myroot.intern"
      flake.inputs.nixpkgs2411;
  "k8s-worker2.srv.myroot.intern" =
    mkSystem "x86_64-linux" "k8s-worker2.srv.myroot.intern"
      flake.inputs.nixpkgs2411;
  "vpn.srv.myroot.intern" = mkSystem "x86_64-linux" "vpn.srv.myroot.intern" flake.inputs.nixpkgs2411;
  "nas.srv.myroot.intern" = mkSystem "x86_64-linux" "nas.srv.myroot.intern" flake.inputs.nixpkgs2411;

  # servers at home
  "priv.srv.home.intern" = mkSystem "aarch64-linux" "priv.srv.home.intern" flake.inputs.nixpkgs2411;
  "proxy.srv.home.intern" = mkSystem "aarch64-linux" "proxy.srv.home.intern" flake.inputs.nixpkgs2411;

  # private systems
  lillysLaptop = mkSystem "x86_64-linux" "lillysLaptop" flake.inputs.nixpkgs2411;

  # home systems
  "lillysWorkstation" = mkSystem "x86_64-linux" "lillysWorkstation" flake.inputs.nixpkgs2411;

  # others
  "lan-server.intern" = mkSystem "x86_64-linux" "lan-server.intern" flake.inputs.nixpkgs2411;
  "installer" = mkSystem "x86_64-linux" "installer" flake.inputs.nixpkgs2411;
}
