{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    custom.devEnv = {
      enable = lib.options.mkEnableOption "installation of development utilities";
      enableFuxVpn = lib.options.mkEnableOption "configuration of fux vpn access";
    };
  };

  config = lib.mkIf config.custom.devEnv.enable {

    sops.secrets = {
      "lilly/kubeconfig.yml" = {
        owner = "lilly";
        group = "nogroup";
        sopsFile = ../dotfiles/lilly/kubectl/config.secret.yml;
        path = "/home/lilly/.kube/config";
        key = ""; # force sops-nix to output the whole file and not just extract one key from the yaml content
        #format = "binary";
      };
      "wg_fux/privkey" = { };
    };

    networking.networkmanager.ensureProfiles = lib.mkIf config.custom.devEnv.enableFuxVpn {
      profiles."wgFux" = {
        connection = {
          id = "wgFux";
          type = "wireguard";
          autoconnect = true;
          interface-name = "wgFux";
          permissions = "user:lilly;";
        };
        wireguard.private-key-flags = 1;
        ipv4 = {
          method = "manual";
          address1 = "172.17.2.251/29";
        };
        "wireguard-peer.bMbuZ+vYhnW2rmme8k2APLpqqMENlQHJrMza6SDEKzw=" = {
          endpoint = "vpn.fux-eg.net:50199";
          allowed-ips = "172.17.2.248/29";
        };
      };
      secrets.entries = [
        {
          matchId = "wgFux";
          matchType = "wireguard";
          matchSetting = "wireguard";
          key = "private-key";
          file = "/run/secrets/wg_fux/privkey";
        }
      ];
    };

    environment.systemPackages = with pkgs; [
      ansible
      ansible-lint
      direnv
      nodejs
      nodePackages.pnpm
      python3
      pipenv
      poetry
      uv
      sshfs
      kubectl
      krew
      kubernetes-helm
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
    ];

    programs.fish.shellInit = ''
      fish_add_path $HOME/.krew/bin
    '';
  };
}
