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
      ] ++ (if config.virtualisation.podman.dockerSocket.enable then [ "podman" ] else [ ]);
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
      };
      home.file = {
        ".ssh/config".source = ../dotfiles/lilly/ssh/config;
        ".ssh/id_code_sign.pub".source = ../dotfiles/lilly/ssh/id_code_sign.pub;
        ".ssh/id_lilly@ccc.pub".source = ../dotfiles/lilly/ssh/id_lilly_ccc.pub;
        ".ssh/id_lilly@lly.sh.pub".source = ../dotfiles/lilly/ssh/id_lilly_lly.sh.pub;
        ".ssh/id_lilly@fux.pub".source = ../dotfiles/lilly/ssh/id_lilly_fux.pub;
        ".ssh/id_lilly@mafiasi.pub".source = ../dotfiles/lilly/ssh/id_lilly_mafiasi.pub;
        ".ietf/ietf.config".source = ../dotfiles/lilly/ietf.config;
      };
      programs.direnv = import ../dotfiles/lilly/direnv;
      programs.ssh.enable = true;
      programs.git = import ../dotfiles/lilly/git.nix { inherit lib pkgs; };
      programs.fish = import ../dotfiles/lilly/fish.nix;
      programs.helix = import ../dotfiles/lilly/helix.nix { inherit lib pkgs config; };
    };
  };
}
