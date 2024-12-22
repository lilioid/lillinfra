{
  modulesPath,
  config,
  lib,
  pkgs,
  home-manager,
  ...
}:
{
  sops.secrets = {
    "ftsell/kubeconfig.yml" = {
      owner = "ftsell";
      group = "nogroup";
      sopsFile = ../dotfiles/ftsell/kubectl/config.secret.yml;
      path = "/home/ftsell/.kube/config";
      format = "binary";
    };
    "wg_fux/privkey" = {};
  };

  networking.networkmanager.ensureProfiles = {
    profiles."wgFux" = {
      connection = {
        id = "wgFux";
        type = "wireguard";
        autoconnect = true;
        interface-name = "wgFux";
        permissions = "user:ftsell;";
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
        matchId = config.networking.networkmanager.ensureProfiles.profiles."wgFux".connection.id;
        matchType = config.networking.networkmanager.ensureProfiles.profiles."wgFux".connection.type;
        matchSetting = "wireguard";
        key = "private-key";
        file = "/run/secrets/wg_fux/privkey";
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    ansible
    ansible-lint
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
    jetbrains.webstorm
    jetbrains.rust-rover
    jetbrains.pycharm-professional
    jetbrains.datagrip
    jetbrains.idea-ultimate
    rustup
    clang
    pkg-config
    pre-commit
    uucp
    openssl
    gleam
    erlang
    terraform
  ];

  programs.fish.shellInit = ''
    fish_add_path $HOME/.krew/bin
  '';
}
