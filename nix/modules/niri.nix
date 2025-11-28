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

  # define color
  colors = {
    pinkMain = "#F5ABB9";
    blueComp = "#abdef5";
    greenComp = "#abf5c2";
    purpleComp = "#abb9f5";
    black = "#000000";

    pinkDark1 = "#d2929e";
    pinkDark2 = "#af7983";
    pinkDark3 = "#8e616a";
    pinkDark4 = "#6e4b51";
    pinkDark5 = "#50353a";
    pinkLight1 = "#f7b4c1";
    pinkLight2 = "#f9bec8";
    pinkLight3 = "#fac7d0";
    pinkLight4 = "#fbd0d8";
    pinkLight5 = "#fcdadf";
  };

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
      configOverride = mkOption {
        description = "Niri configuration overrides";
        default = {};
        type = lib.types.attrsOf lib.types.attrs;
      };
    };
  };

  # implementation
  config = lib.mkIf cfg.enable {
    #
    # general system configuration
    # 
    custom.desktopApps.enableCommon = true;
    niri-flake.cache.enable = lib.mkForce false;
    programs.niri.enable = true;
    programs.niri.package = pkgs.niri;
    qt.style = "adwaita";
    networking.networkmanager.enable = true;
    services.upower.enable = true;
    
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

    services.displayManager.enable = true;
    services.xserver = {
      displayManager.gdm.enable = true;
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
      services.ssh-agent.enable = true;

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

        outputs = {};  # override this via the configOverride option

        cursor = {
          theme = homeConfig.home.pointerCursor.name;
          size = homeConfig.home.pointerCursor.size;
        };

        layout = {
          gaps = 6;
          center-focused-column = "never";
          always-center-single-column = true;
          background-color = colors.black;
          preset-column-widths = [
            { proportion = 1.0 / 3.0; }
            { proportion = 0.5; }
            { proportion = 2.0 / 3.0; }
          ];
          preset-window-heights = [
            { proportion = 0.2; }
            { proportion = 0.5; }
            { proportion = 0.8; }
          ];
          default-column-width = { proportion = 0.5; };
          focus-ring = {
            width = 3;
            active = { color = colors.pinkMain; };
            inactive = { color = colors.pinkDark5; };
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

        workspaces = {
          "comm" = {};
        };

        window-rules = [
          {
            matches = [{ app-id="^firefox$"; title="^Picture-in-Picture$"; }];
            open-floating = true;
          }
          {
            matches = [{ app-id="^org\\.keepasxc\\.KeePassXC$"; }];
            block-out-from = "screen-capture";
          }
          {
            matches = [{ app-id="^thunderbid$"; title = "^\\d+ Reminder(s?)$"; }];
            open-floating = true;
            open-focused = true;
            open-on-workspace = null;
          }
          {
            # open some windows with 1/3 proportion by default because they dont scale well
            matches = [{ app-id="^firefox$"; is-floating=false; }];
            default-column-width = { proportion = 2.0 / 3.0; };
          }
          {
            matches = [{ app-id="^thunderbid$"; }];
            open-maximized = true;
            open-on-workspace = "comm";
          }
          {
            # open certain apps on comms workspace
            matches = [
              { app-id="^thunderbird$"; }
            ];
            open-on-workspace = "comms";
          }
          {
            # default matcher that styles all windows
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
            action = niriActions.spawn [ "${lib.getExe scripts.lock-niri}" ];
          };
          "Mod+Dead_Circumflex" = {
            hotkey-overlay.title = "Toggle Notification-Center";
            action = niriActions.spawn [ "swaync-client" "--toggle-panel" ];
          };
          "Mod+Shift+Dead_Circumflex" = {
            hotkey-overlay.title = "Toggle DnD";
            action = niriActions.spawn [ "swaync-client" "--togle-dnd" ];
          };
          "Mod+Escape" = {
            hotkey-overlay.title = "Toggle Overview";
            action = niriActions.toggle-overview;
          };
          "Mod+Q" = {
            repeat = false;
            action = niriActions.close-window;
          };
          "Mod+E" = {
            hotkey-overlay.title = "Open Emoji Picker";
            repeat = false;
            action = niriActions.spawn [ "rofi" "-show" "emoji" ];
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
            cooldown-ms = 100;
            action = niriActions.focus-column-right;
          };
          "Mod+WheelScrollUp" = {
            cooldown-ms = 100;
            action = niriActions.focus-column-left;
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

          "Ctrl+Shift+Left".action = niriActions.set-column-width "-5%";
          "Ctrl+Shift+Down".action = niriActions.set-window-height "+5%";
          "Ctrl+Shift+Up".action = niriActions.set-window-height "-5%";
          "Ctrl+Shift+Right".action = niriActions.set-column-width "+5%";

          "Mod+Comma".action = niriActions.consume-or-expel-window-left;
          "Mod+Period".action = niriActions.consume-or-expel-window-right;

          "Mod+R".action = niriActions.switch-preset-column-width;
          "Mod+Shift+R".action = niriActions.switch-preset-window-height;
          "Mod+F".action = niriActions.maximize-column;
          "Mod+Shift+F".action = niriActions.fullscreen-window;
          "Mod+C".action = niriActions.center-visible-columns;
          "Mod+Shift+Space".action = niriActions.toggle-window-floating;
          "Print".action.screenshot = {};
          "Ctrl+Alt+Delete".action = niriActions.quit;
        };
      } // cfg.configOverride;

      # application picker
      programs.rofi = {
        enable = true;
        modes = [ "drun" "emoji" "calc" "recursivebrowser" ];
        terminal = lib.getExe pkgs.kitty;
        plugins = with pkgs; [ rofi-calc rofi-emoji ];
      };

      # notification center
      services.swaync = {
        enable = true;
      };

      # status bar
      programs.waybar = {
        enable = true;
        systemd.target = "niri.service";
        settings = {
          topBar = {
            layer = "top";
            position = "top";
            modules-left = [ "niri/workspaces" "niri/window" ];
            modules-center = [ "clock" ];
            modules-right = [ "network" "wireplumber" "power-profiles-daemon" "tray" "group/group-power" ];
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
