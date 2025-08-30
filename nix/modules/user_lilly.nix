{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
let
  hasDesktop = config.custom.gnomeDesktop.enable;
in
{
  options = {
    custom.user.enable = lib.options.mkOption {
      default = true;
      description = "Whether to enable creation and configuration of my user account";
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.custom.user.enable {
    programs.fish.enable = true;

    users.users.lilly = {
      createHome = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "dialout"
      ] ++ (if config.virtualisation.podman.dockerSocket.enable then [ "podman" ] else [ ])
        ++ (if config.virtualisation.docker.enable then [ "docker" ] else []);
      home = "/home/lilly";
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPzGnNKyn6jmVxig4SRnTBfpi6okPU2aOHPwFnAPTxJm ftsell@ftsell.de"
      ];
      hashedPassword = "$y$j9T$x55BKHAikhaUeAPN6GsCa/$uig7LwmWeodvbBKKMmlO7k/UbtU.Za6RuS.QI5O5ag9";
      isNormalUser = true;
    };

    home-manager.users.lilly = {
      home.preferXdgDirectories = true;
      programs.wezterm.enable = hasDesktop;
      programs.wezterm.extraConfig = lib.mkIf hasDesktop (
        builtins.readFile ../dotfiles/lilly/wezterm.lua
      );
      xdg.mimeApps = lib.mkIf hasDesktop (import ../dotfiles/lilly/mimeapps.nix);
      xdg.configFile = {
        "mimeapps.list" = lib.mkIf hasDesktop { force = true; };
        "nixpkgs/config.nix".text = ''
          {
            allowUnfree = true;
          }
        '';
        "jj/config.toml" = {
          enable = config.home-manager.users.lilly.programs.jujutsu.enable;
          source = ../dotfiles/lilly/jj/config.toml;
        };
      };
      home.file = {
        ".ssh/config".source = ../dotfiles/lilly/ssh/config;
        ".ssh/id_code_sign.pub".source = ../dotfiles/lilly/ssh/id_code_sign.pub;
        ".ssh/id_lilly@ccc.pub".source = ../dotfiles/lilly/ssh/id_lilly_ccc.pub;
        ".ssh/id_lilly@lly.sh.pub".source = ../dotfiles/lilly/ssh/id_lilly_lly.sh.pub;
        ".ssh/id_lilly@fux.pub".source = ../dotfiles/lilly/ssh/id_lilly_fux.pub;
        ".ssh/id_lilly@mafiasi.pub".source = ../dotfiles/lilly/ssh/id_lilly_mafiasi.pub;
        ".ssh/id_lilly@hanse.de.pub".source = ../dotfiles/lilly/ssh/id_lilly_hanse.pub;
        ".ssh/id_sell@b1-systems.de.pub".source = ../dotfiles/lilly/ssh/id_sell_b1.pub;
        ".ietf/ietf.config".source = ../dotfiles/lilly/ietf.config;
      };
      programs.direnv = import ../dotfiles/lilly/direnv;
      programs.ssh.enable = true;
      programs.git = import ../dotfiles/lilly/git.nix { inherit lib pkgs; };
      programs.fish = import ../dotfiles/lilly/fish.nix;
      programs.helix = import ../dotfiles/lilly/helix.nix { inherit lib pkgs config; };
      programs.taskwarrior = lib.mkIf config.custom.devEnv.enable (import ../dotfiles/lilly/taskwarrior.nix { inherit config pkgs; }).taskwarrior;
      services.taskwarrior-sync = lib.mkIf config.custom.devEnv.enable (import ../dotfiles/lilly/taskwarrior.nix { inherit config pkgs; }).taskwarrior-sync;
    };

    sops = {
      secrets."lilly/taskchampion-sync-client-id" = lib.mkIf config.custom.devEnv.enable {
        owner = "lilly";
      };
      secrets."lilly/taskchampion-sync-encryption-secret" = lib.mkIf config.custom.devEnv.enable {
        owner = "lilly";
        sopsFile = ../data/shared-secrets/task-sync.yml;
      };
      templates."lilly/taskrc" = lib.mkIf config.custom.devEnv.enable {
        owner = "lilly";
        content = ''
          sync.server.url=https://task-sync.lly.sh
          sync.server.client_id=${config.sops.placeholder."lilly/taskchampion-sync-client-id"}
          sync.encryption_secret=${config.sops.placeholder."lilly/taskchampion-sync-encryption-secret"}
        '';
      };
    };

    environment.systemPackages = [
      (lib.mkIf config.custom.devEnv.enable pkgs.taskwarrior-tui)
    ];
  };
}
