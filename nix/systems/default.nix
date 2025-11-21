{ flake, mkPkgs }:
let
  # read all files in ../modules and build the full path to them
  customModules = builtins.map
    (i: ../modules/${i})
    (builtins.attrNames (builtins.readDir ../modules));

  # helper to create a nixos system
  mkSystem =
    systemType: name: nixpkgs:
    let
      lib = nixpkgs.lib;
      systemModule = if lib.pathIsDirectory ./${name} then ./${name} else ./${name}.nix;
      pkgs = mkPkgs nixpkgs systemType;
    in
    nixpkgs.lib.nixosSystem {
      specialArgs = flake.inputs;
      modules = [
        flake.inputs.disko.nixosModules.disko
        flake.inputs.home-manager.nixosModules.home-manager
        flake.inputs.sops-nix.nixosModules.default
        flake.inputs.lix.nixosModules.default
        flake.inputs.cookied.nixosModules.default
      ] ++ customModules ++ [

        systemModule

        (
          let
            fqdnParts = nixpkgs.lib.strings.splitString "." name;
          in
          {
            # nixpkgs settings based on function inputs
            nixpkgs.pkgs = pkgs;
            nix.nixPath = [
              "nixpkgs=${lib.cleanSource nixpkgs}"
              "nixpkgs-unstable=${lib.cleanSource flake.inputs.nixpkgs-unstable}"
            ];
            nix.registry = {
              nixpkgs.flake = nixpkgs;
              nixpkgs-unstable.flake = flake.inputs.nixpkgs-unstable;
            };

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
  "rt-hosting.srv.lly.sh" = mkSystem "x86_64-linux" "rt-hosting.srv.lly.sh" flake.inputs.nixpkgs2505;
  "mail.srv.lly.sh" = mkSystem "x86_64-linux" "mail.srv.lly.sh" flake.inputs.nixpkgs2505;
  "gtw.srv.lly.sh" = mkSystem "x86_64-linux" "gtw.srv.lly.sh" flake.inputs.nixpkgs2505;

  # internal hosts at myroot
  "k8s-ctl.srv.myroot.intern" =
    mkSystem "x86_64-linux" "k8s-ctl.srv.myroot.intern"
      flake.inputs.nixpkgs2505;
  "k8s-worker1.srv.myroot.intern" =
    mkSystem "x86_64-linux" "k8s-worker1.srv.myroot.intern"
      flake.inputs.nixpkgs2505;
  "k8s-worker2.srv.myroot.intern" =
    mkSystem "x86_64-linux" "k8s-worker2.srv.myroot.intern"
      flake.inputs.nixpkgs2505;
  "vpn.srv.myroot.intern" = mkSystem "x86_64-linux" "vpn.srv.myroot.intern" flake.inputs.nixpkgs2505;
  "nas.srv.myroot.intern" = mkSystem "x86_64-linux" "nas.srv.myroot.intern" flake.inputs.nixpkgs2505;

  # servers at home
  "priv.srv.home.intern" = mkSystem "aarch64-linux" "priv.srv.home.intern" flake.inputs.nixpkgs2505;
  "proxy.srv.home.intern" = mkSystem "aarch64-linux" "proxy.srv.home.intern" flake.inputs.nixpkgs2505;

  # aut-sys.de
  "db.z9.aut-num.de" = mkSystem "x86_64-linux" "db.z9.aut-num.de" flake.inputs.nixpkgs2505;
  "webhost.z9.aut-num.de" = mkSystem "x86_64-linux" "webhost.z9.aut-num.de" flake.inputs.nixpkgs2505;
  "syncthing.z9.aut-num.de" = mkSystem "x86_64-linux" "syncthing.z9.aut-num.de" flake.inputs.nixpkgs2505;
  "k8s-ctl.z9.aut-num.de" = mkSystem "x86_64-linux" "k8s-ctl.z9.aut-num.de" flake.inputs.nixpkgs2505;
  "k8s-worker1.z9.aut-num.de" = mkSystem "x86_64-linux" "k8s-worker1.z9.aut-num.de" flake.inputs.nixpkgs2505;
  "k8s-worker2.z9.aut-num.de" = mkSystem "x86_64-linux" "k8s-worker2.z9.aut-num.de" flake.inputs.nixpkgs2505;
  "k8s-worker3.z9.aut-num.de" = mkSystem "x86_64-linux" "k8s-worker3.z9.aut-num.de" flake.inputs.nixpkgs2505;

  # private systems
  "lillysLaptop" = mkSystem "x86_64-linux" "lillysLaptop" flake.inputs.nixpkgs2505;
  "lillysWorkLaptop" = mkSystem "x86_64-linux" "lillysWorkLaptop" flake.inputs.nixpkgs2505;
  "lillysWorkstation" = mkSystem "x86_64-linux" "lillysWorkstation" flake.inputs.nixpkgs2505;

  # others
  "lan-server.intern" = mkSystem "x86_64-linux" "lan-server.intern" flake.inputs.nixpkgs2505;
  "installer" = mkSystem "x86_64-linux" "installer" flake.inputs.nixpkgs2505;
  "proxmox-lxc" = mkSystem "x86_64-linux" "proxmox-lxc" flake.inputs.nixpkgs2505;
}
