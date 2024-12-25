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

    users.users.ftsell = {
      createHome = true;
      extraGroups = [
        "wheel"
        "networkmanager"
      ] ++ (if config.virtualisation.podman.dockerSocket.enable then [ "podman" ] else [ ]);
      home = "/home/ftsell";
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPzGnNKyn6jmVxig4SRnTBfpi6okPU2aOHPwFnAPTxJm ftsell@ftsell.de"
      ];
      hashedPassword = "$y$j9T$x55BKHAikhaUeAPN6GsCa/$uig7LwmWeodvbBKKMmlO7k/UbtU.Za6RuS.QI5O5ag9";
      isNormalUser = true;
    };

    home-manager.users.ftsell = {
      home.preferXdgDirectories = true;
      programs.wezterm.enable = hasDesktop;
      programs.wezterm.extraConfig = lib.mkIf hasDesktop (
        builtins.readFile ../dotfiles/ftsell/wezterm/wezterm.lua
      );
      xdg.mimeApps = lib.mkIf hasDesktop (import ../dotfiles/ftsell/mimeapps.nix);
      home.file = {
        ".ssh/config".source = ../dotfiles/ftsell/ssh/config;
        ".ssh/id_code_sign.pub".source = ../dotfiles/ftsell/ssh/id_code_sign.pub;
        ".ssh/id_lilly@ccc.pub".source = ../dotfiles/ftsell/ssh/id_lilly_ccc.pub;
        ".ssh/id_lilly@lly.sh.pub".source = ../dotfiles/ftsell/ssh/id_lilly_lly.sh.pub;
        ".ssh/id_lilly@fux.pub".source = ../dotfiles/ftsell/ssh/id_lilly_fux.pub;
        ".ietf/ietf.config".source = ../dotfiles/ftsell/ietf.config;
      };
      programs.direnv = import ../dotfiles/ftsell/direnv;
      programs.ssh.enable = true;
      programs.git = import ../dotfiles/ftsell/git.nix { inherit lib pkgs; };
      programs.fish = import ../dotfiles/ftsell/fish.nix;
      programs.helix = import ../dotfiles/ftsell/helix.nix { inherit lib pkgs config; };
    };
  };
}
