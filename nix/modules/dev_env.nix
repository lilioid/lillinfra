{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.devEnv;
in
{
  options = {
    custom.devEnv = {
      enable = lib.options.mkEnableOption "installation of development utilities";
      enableFuxVpn = lib.options.mkEnableOption "configuration of fux vpn access";
      enableAutSysMgmtVpn = lib.options.mkEnableOption "configuration of aut-sys vpn";
    };
  };

  config = lib.mkIf cfg.enable {
    # add aarch64-linux as supported binary format if this is an x64 system
    # this is needed to support nixos-rebuild for systems in aarch64 format
    boot.binfmt.emulatedSystems = lib.mkIf (config.nixpkgs.hostPlatform.system == "x86_64-linux") [
      "aarch64-linux"
    ];

    sops.secrets = {
      "lilly/kubeconfig.yml" = {
        owner = "lilly";
        group = "nogroup";
        sopsFile = ../dotfiles/lilly/kubectl/config.secret.yml;
        path = "/home/lilly/.kube/config";
        key = ""; # force sops-nix to output the whole file and not just extract one key from the yaml content
        #format = "binary";
      };
      "wg_fux/privkey" = lib.mkIf cfg.enableFuxVpn { };
      "wg_autsysmgmt/privkey" = lib.mkIf cfg.enableAutSysMgmtVpn {};
    };

    home-manager.users.lilly = {
      programs.jujutsu = {
        enable = true;
        ediff = lib.mkForce false;
      };
      home.sessionSearchVariables = {
        PATH = [ "$HOME/.krew/bin" ];
      };
    };

    networking.networkmanager.ensureProfiles = {
      profiles."wgFux" = lib.mkIf cfg.enableFuxVpn {
        connection = {
          id = "wgFux";
          type = "wireguard";
          autoconnect = true;
          interface-name = "wgFux";
          permissions = "user:lilly:;";
        };
        wireguard = {
          private-key-flags = 1;
        };
        ipv4 = {
          method = "manual";
          address1 = "172.17.2.251/29";
        };
        ipv6 = {
          method = "manual";
          address1 = "2a07:c481:0:2::251/64";
        };
        "wireguard-peer.bMbuZ+vYhnW2rmme8k2APLpqqMENlQHJrMza6SDEKzw=" = {
          allowed-ips = "172.16.0.0/12;2a07:c481:0:1::/64;2a07:c481:0:2::/64;";
          endpoint = "vpn.fux-eg.net:50199";
        };
      };
      profiles."autSys" = lib.mkIf cfg.enableAutSysMgmtVpn {
        connection = {
          id = "wgAutSysMgmt";
          type = "wireguard";
          autoconnect = true;
          interface-name = "wgAutSysMgmt";
          permissions = "user:lilly:;";
        };
        wireguard = {
          private-key-flags = 1;
        };
        ipv4 = {
          method = "manual";
          address1 = "10.233.227.2/24";
        };
        ipv6 = {
          method = "manual";
          address1 = "2a07:c481:2:3::2/64";
        };
        "wireguard-peer.SySg/p4N+TEx874Rnlt/7vNmXhQPQNE+WpBDk791dww=" = {
          allowed-ips = lib.strings.concatStringsSep ";" [
            "10.233.226.0/24"    # mgmt network
            "10.233.227.0/24"    # mgmt vpn
            "2a07:c481:2:2::/64" # mgmt network
            "2a07:c481:2:3::/64" # mgmt vpn
          ];
          endpoint = "vpn.aut-sys.de:13231";
        };
      };
      secrets.entries = [
        (lib.mkIf cfg.enableFuxVpn {
          matchId = "wgFux";
          matchType = "wireguard";
          matchSetting = "wireguard";
          key = "private-key";
          file = config.sops.secrets."wg_fux/privkey".path;
        })
        (lib.mkIf cfg.enableAutSysMgmtVpn {
          matchId = "wgAutSysMgmt";
          matchType = "wireguard";
          matchSetting = "wireguard";
          key = "private-key";
          file = config.sops.secrets."wg_autsysmgmt/privkey".path;
        })
      ];
    };
  
    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
    };

    environment.systemPackages = with pkgs; [
      nixos-rebuild-ng
      glab
      helmfile
      jq
      watchexec
      ansible
      ansible-lint
      direnv
      dig
      nodejs
      nodePackages.pnpm
      bun
      python3
      uv
      kubectl
      krew
      kubernetes-helm
      k9s
      pass
      sshuttle
      rustup
      pre-commit
      openssl
      gleam
      erlang
      terraform
      ietf-cli
      sequoia-sq
      subnetcalc
      attic-client
      nil
      reuse
      tig
      jetbrains.pycharm-professional
      jetbrains.rust-rover
      jetbrains.webstorm
    ];

    programs.fish.shellInit = ''
      fish_add_path $HOME/.krew/bin
    '';
  };
}
