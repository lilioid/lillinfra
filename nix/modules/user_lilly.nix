{ modulesPath
, config
, lib
, pkgs
, ...
}:
let
  hasGnome = config.custom.gnomeDesktop.enable;
  hasNiri = config.custom.niri.enable;
  hasDevEnv = config.custom.devEnv.enable;
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
      ++ (if config.virtualisation.docker.enable then [ "docker" ] else [ ]);
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
      home.sessionSearchVariables = lib.mkIf hasDevEnv {
        PATH = [ "$HOME/.krew/bin" ];
      };
      programs.wezterm.enable = hasGnome;
      programs.wezterm.extraConfig = lib.mkIf hasGnome (
        builtins.readFile ../dotfiles/lilly/wezterm.lua
      );
      xdg.mimeApps = lib.mkIf hasGnome (import ../dotfiles/lilly/mimeapps.nix);
      xdg.configFile = {
        "mimeapps.list" = lib.mkIf hasGnome { force = true; };
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
      programs.jujutsu = {
        enable = true;
        ediff = lib.mkForce false;
      };
      programs.taskwarrior = lib.mkIf hasDevEnv (import ../dotfiles/lilly/taskwarrior.nix { inherit config pkgs lib; }).taskwarrior;
      services.taskwarrior-sync = lib.mkIf hasDevEnv (import ../dotfiles/lilly/taskwarrior.nix { inherit config pkgs lib; }).taskwarrior-sync;
      programs.rofi = lib.mkIf hasNiri {
        enable = true;
        modes = [ "drun" "emoji" "calc" "recursivebrowser" ];
        terminal = lib.getExe pkgs.kitty;
        plugins = with pkgs; [ rofi-calc rofi-emoji ];
      };
      services.swaync = {
        enable = hasNiri;
      };
      services.ssh-agent.enable = true;
      programs.waybar = {
        enable = hasNiri;
        systemd.target = "niri.service";
        settings = {
          topBar = {
            layer = "top";
            position = "top";
            modules-left = [ "niri/workspaces" "niri/window" ];
            modules-center = [ "clock" ];
            modules-right = [ "wireplumber" "power-profiles-daemon" "tray" "group/group-power" ];
            clock = {
              timezone = "Europe/Berlin";
              tooltip-format = "<tt>{calendar}</tt>";
              calendar = {
                mode = "month";
                mode-mon-col = 3;
                weeks-pos = "left";
                on-scroll = 1;
                format = {
                  months = "<span color='#ffead3'><b>{}</b></span>";
                  days = "<span color='#ecc6d9'><b>{}</b></span>";
                  weeks  = "<span color='#99ffdd'><b>W{}</b></span>";
                  weekdays = "<span color='#ffcc66'><b>{}</b></span>";
                  today = "<span color='#ff6699'><b><u>{}</u></b></span>";
                };
              };
              actions = {
                on-click-right = "shift_reset";
                on-scroll-up = "shift_up";
                on-scroll-down = "shift_down";
              };
            };
            tray = {};
            "group/group-power" = {
              orientation = "inherit";
              drawer = {
                transition-duration = 500;
                children-class = "not-power";
                transition-left-to-right = false;
              };
              modules = [ "custom/poweroff" "custom/lock" "custom/quit" "custom/reboot" ];
            };
            "custom/poweroff" = {
              format = "";
              tooltip-format = "Poweroff";
              on-click = "systemctl poweroff";
            };
            "custom/lock" = {
              format = "󰍁";
              tooltip-format = "Lock";
              on-click = "swaylock --show-keyboard-layout --indicator-caps-lock --image=~/Sync/Wallpapers/ccc-camp.jpg";
            };
            "custom/quit" = {
              format = "󰗼";
              tooltip-format = "Exit Niri";
              on-click = "niri msg action quit";
            };
            "custom/reboot" = {
              format = "󰜉";
              tooltip-format = "Reboot";
              on-click = "systemctl reboot";
            };
          };
        };
        style = null;
      };
      home.pointerCursor = {
        enable = true;
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 24;
      };
    };

    sops = {
      secrets."lilly/kubeconfig.yml" = lib.mkIf hasDevEnv {
        owner = "lilly";
        group = "nogroup";
        sopsFile = ../dotfiles/lilly/kubectl/config.secret.yml;
        path = "/home/lilly/.kube/config";
        key = ""; # force sops-nix to output the whole file and not just extract one key from the yaml content
      };
      secrets."lilly/taskchampion-sync-client-id" = lib.mkIf hasDevEnv {
        owner = "lilly";
      };
      secrets."lilly/taskchampion-sync-encryption-secret" = lib.mkIf hasDevEnv {
        owner = "lilly";
        sopsFile = ../data/shared-secrets/task-sync.yml;
      };
      templates."lilly/taskrc" = lib.mkIf hasDevEnv {
        owner = "lilly";
        content = ''
          sync.server.url=https://task-sync.aut-sys.de
          sync.server.client_id=${config.sops.placeholder."lilly/taskchampion-sync-client-id"}
          sync.encryption_secret=${config.sops.placeholder."lilly/taskchampion-sync-encryption-secret"}
        '';
      };
    };

    environment.systemPackages = [
      (lib.mkIf hasDevEnv pkgs.taskwarrior-tui)
    ];
  };
}
