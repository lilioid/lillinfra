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
    };

    home-manager.users.lilly = {
      programs.emacs = {
        enable = true;
        extraConfig = builtins.readFile ../dotfiles/lilly/emacs.el;
        extraPackages = epkgs: [
          epkgs.neotree
          epkgs.nerd-icons
          epkgs.tree-sitter
          epkgs.tree-sitter-langs
          pkgs.nil
        ];
      };
    };

    networking.networkmanager.ensureProfiles = lib.mkIf cfg.enableFuxVpn {
      profiles."wgFux" = {
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
      secrets.entries = [
        {
          matchId = "wgFux";
          matchType = "wireguard";
          matchSetting = "wireguard";
          key = "private-key";
          file = config.sops.secrets."wg_fux/privkey".path;
        }
      ];
    };
  
    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
    };

    environment.systemPackages = with pkgs; [
      nixos-rebuild-ng
      ansible
      ansible-lint
      direnv
      dig
      nodejs
      nodePackages.pnpm
      bun
      python3
      pipenv
      poetry
      uv
      sshfs
      kubectl
      krew
      kubernetes-helm
      k9s
      pass
      sshuttle
      rustup
      clang
      pkg-config
      pre-commit
      uucp
      openssl
      gleam
      erlang
      terraform
      ietf-cli
      sequoia-sq
      subnetcalc
      attic-client
      nil
      jetbrains.pycharm-professional
      jetbrains.rust-rover
      jetbrains.webstorm
    ];

    programs.fish.shellInit = ''
      fish_add_path $HOME/.krew/bin
    '';
  };
}
