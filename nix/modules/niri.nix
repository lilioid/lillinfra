{
  config,
  lib,
  pkgs,
  ...
}: let
  homeConfig = config.home-manager.users.lilly;
  cfg = config.custom.niri;
  isUserEnabled = config.custom.user.enable;
  niriActions = homeConfig.lib.niri.actions;

  # helper scripts which are used in multiple locations
  scripts.lock-niri = pkgs.writeShellScriptBin "lock-niri.sh" ''
     exec swaylock \
       --show-keyboard-layout \
       --indicator-caps-lock \
       --image=~/Sync/Wallpapers/ccc-camp.jpg;
  '';
in {
  imports = [
    ./desktop_apps.nix
  ];
  
  # option definitions
  options = with lib.options; {
    custom.niri = {
      enable = mkEnableOption "a configured niri desktop environment";
    };
  };

  # implementation
  config = lib.mkIf cfg.enable {
    #
    # general system configuration
    # 
    niri-flake.cache.enable = lib.mkForce false;
    programs.niri.enable = true;
    programs.niri.package = pkgs.niri;
    qt.style = "adwaita";

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      xdgOpenUsePortal = true;
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    };

    fonts = {
      packages = with pkgs; [ inter nerd-fonts.jetbrains-mono ];
      fontconfig.defaultFonts = {
        sansSerif = [ "Inter" ];
      };
    };
    
    services.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    environment.systemPackages = with pkgs; [
      xwayland-satellite
      swaylock
      swaynotificationcenter
    ];

    #
    # user-specific settings, rendered via home-manager
    #
    home-manager.users.lilly = lib.mkIf isUserEnabled {
      # ref: https://yalter.github.io/niri/Configuration%3A-Introduction.html
      programs.niri.settings = {
        input = {
          warp-mouse-to-focus.enable = true;
          keyboard = {
            numlock = true;
            xkb = {
              layout = "de";
            };
          };
          touchpad = {
            tap  = true;
            dwt = true;
            drag = true;
            natural-scroll = true;
            accel-speed = 0.1;
            accel-profile = "adaptive";
            left-handed = true;
            scroll-method = "two-finger";
            scroll-factor = 0.8;
          };
          mouse = {};
          trackpoint = {};
        };

        outputs = {
          "eDP-1" = {
            mode.height = 1800;
            mode.width = 2880;
            mode.refresh = 90.001;
            scale = 1.5;
            focus-at-startup = true;
          };
        };

        cursor = {
          theme = homeConfig.home.pointerCursor.name;
          size = homeConfig.home.pointerCursor.size;
        };

        layout = {
          gaps = 6;
          center-focused-column = "never";
          always-center-single-column = true;
          background-color = "#000000";
          preset-column-widths = [
            { proportion = 1.0 / 3.0; }
            { proportion = 0.5; }
            { proportion = 1.0 / 3.0 * 2.0; }
          ];
          preset-window-heights = [
            { proportion = 0.2; }
            { proportion = 1.0 / 3.0; }
            { proportion = 0.5; }
            { proportion = 1.0 / 3.0 * 2.0; }
            { proportion = 0.8; }
            { proportion = 1.0; }
          ];
          default-column-width = { proportion = 0.5; };
          focus-ring = {
            width = 2;
            active = { color ="#f5abb9"; };
            inactive = { color = "#bfadf5"; };
          };
          struts = rec {
            left = 24;
            right = left;
          };
        };

        prefer-no-csd = true;
        screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
        
        environment = {
          XDG_CURRENT_DESKTOP = "niri:GNOME";
          SSH_AUTH_SOCK = "/run/user/1000/ssh-agent";
          QT_QPA_PLATFORM = "wayland";
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
          GTK_USE_PORTAL = "1";
          MOZ_ENABLE_WAYLAND = "1";
        };

        overview = {
          zoom = 0.8;
        };

        window-rules = [
          {
            matches = [{ app-id="firefox$"; title="^Picture-in-Picture$"; }];
            open-floating = true;
          }
          {
            matches = [{ app-id="^org\\.keepasxc\\.KeePassXC$"; }];
            block-out-from = "screen-capture";
          }
          {
            geometry-corner-radius = rec {
              top-left = 4.0;
              top-right = top-left;
              bottom-left = top-left;
              bottom-right = top-left;
            };
            clip-to-geometry = true;
          }
        ];

        binds = {
          "F1".action = niriActions.show-hotkey-overlay;
          "Mod+Return" = {
            hotkey-overlay.title = "Open Terminal";
            repeat = false;
            action = niriActions.spawn [ "kitty" ];
          };
          "Mod+D" = {
            hotkey-overlay.title = "Open Application picker";
            repeat = false;
            action = niriActions.spawn [ "rofi" "-show" "drun" ];
          };
          "Mod+L" = {
            hotkey-overlay.title = "Lock the Screen";
            repeat = false;
            action = niriActions.spawn [ "${scripts.lock-niri}" ];
          };
          "Mod+T" = {
            hotkey-overlay.title = "Toggle Notification-Center";
            cooldown-ms = 2 * 1000;
            action = niriActions.spawn [ "swaync-client" "--toggle-panel" ];
          };
          "Mod+O" = {
            hotkey-overlay.title = "Toggle Overview";
            action = niriActions.toggle-overview;
          };
          "Alt+F4" = {
            repeat = false;
            action = niriActions.close-window;
          };
          "XF86AudioRaiseVolume" = {
            allow-when-locked = true;
            action = niriActions.spawn [ "wpctl" "set-volume" "@DEFAULT_ADUIO_SINK@" "0.1+" ];
          };
          "XF86AudioLowerVolume" = {
            allow-when-locked = true;
            action = niriActions.spawn [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-" ];
          };
          "XF86AudioMute" = {
            allow-when-locked = true;
            action = niriActions.spawn [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle" ];
          };
          "XF86AudioMicMute" = {
            allow-when-locked = true;
            action = niriActions.spawn [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle" ];
          };

          "Mod+Left".action = niriActions.focus-column-or-monitor-left;
          "Mod+Down".action = niriActions.focus-window-down;
          "Mod+Right".action = niriActions.focus-column-or-monitor-right;
          "Mod+Up".action = niriActions.focus-window-up;

          "Mod+Shift+Left".action = niriActions.move-column-left-or-to-monitor-left;
          "Mod+Shift+Down".action = niriActions.move-window-down;
          "Mod+Shift+Right".action = niriActions.move-column-right-or-to-monitor-right;
          "Mod+Shift+Up".action = niriActions.move-window-up;

          "Mod+Home".action = niriActions.focus-column-first;
          "Mod+End".action = niriActions.focus-column-last;
          "Mod+Shift+Home".action = niriActions.move-column-to-first;
          "Mod+Shift+End".action = niriActions.move-column-to-last;

          "Mod+Page_Down".action = niriActions.focus-workspace-down;
          "Mod+Page_Up".action = niriActions.focus-workspace-up;
          "Mod+Shift+Page_Down".action = niriActions.move-column-to-workspace-down;
          "Mod+Shift+Page_Up".action = niriActions.move-column-to-workspace-up;

          "Mod+WheelScrollDown" = {
            cooldown-ms = 150;
            action = niriActions.focus-workspace-down;
          };
          "Mod+WheelScrollUp" = {
            cooldown-ms = 150;
            action = niriActions.focus-workspace-up;
          };

          "Mod+1".action = niriActions.focus-workspace 1;
          "Mod+2".action = niriActions.focus-workspace 2;
          "Mod+3".action = niriActions.focus-workspace 3;
          "Mod+4".action = niriActions.focus-workspace 4;
          "Mod+5".action = niriActions.focus-workspace 5;
          "Mod+6".action = niriActions.focus-workspace 6;
          "Mod+7".action = niriActions.focus-workspace 7;
          "Mod+8".action = niriActions.focus-workspace 8;
          "Mod+9".action = niriActions.focus-workspace 9;
          "Mod+Shift+1".action.move-column-to-workspace = 1;
          "Mod+Shift+2".action.move-column-to-workspace = 2;
          "Mod+Shift+3".action.move-column-to-workspace = 3;
          "Mod+Shift+4".action.move-column-to-workspace = 4;
          "Mod+Shift+5".action.move-column-to-workspace = 5;
          "Mod+Shift+6".action.move-column-to-workspace = 6;
          "Mod+Shift+7".action.move-column-to-workspace = 7;
          "Mod+Shift+8".action.move-column-to-workspace = 8;
          "Mod+Shift+9".action.move-column-to-workspace = 9;

          "Mod+Comma".action = niriActions.consume-or-expel-window-left;
          "Mod+Period".action = niriActions.consume-or-expel-window-right;

          "Mod+R".action = niriActions.switch-preset-column-width;
          "Mod+Shift+R".action = niriActions.switch-preset-window-height;
          "Mod+F".action = niriActions.maximize-column;
          "Mod+Shift+F".action = niriActions.fullscreen-window;
          "Mod+C".action = niriActions.center-column;
          "Mod+Minus".action = niriActions.set-column-width "-10%";
          "Mod+Plus".action = niriActions.set-column-width "+10%";
          "Mod+Space".action = niriActions.toggle-window-floating;

          # "Print".action = niriActions.screenshot { show-pointer = false; };
          "Print".action.screenshot = {};
          "Ctrl+Alt+Delete".action = niriActions.quit;
        };
      };

      # configure a background image daemon
      systemd.user.services."swaybg" = {
        Unit = {
          Description = "niri background daemon";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          Type = "exec";
          ExecStart = ''${lib.getExe pkgs.swaybg} --image "/home/lilly/Sync/Wallpapers/Queer Smoke/aesthr-smoke-trans.png" --output "*" --mode fill'';
        };
        Install = {
          WantedBy = [ "niri.service" ];
        };
      };
    };
  };
}
