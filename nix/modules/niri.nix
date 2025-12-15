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
    white = "#FFFFFF";

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
      additionalWindowRules = mkOption {
        description = "Additional window-rules to add without overriding existing ones";
        default = [];
        type = lib.types.listOf lib.types.attrs;
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
    services.power-profiles-daemon.enable = true;
    # programs.dconf.enable = true;    # needed to set gtk theme
    
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      xdgOpenUsePortal = true;
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    };

    fonts = {
      packages = with pkgs; [ inter nerd-fonts.jetbrains-mono nerd-fonts.symbols-only ];
      fontconfig.defaultFonts = {
        sansSerif = [ "Symbols Nerd Font" "Inter" ];
        monospace = [ "JetBrainsMono NF" ];
      };
    };
    
    services.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    services.displayManager.enable = true;
    services.displayManager.gdm.enable = true;

    environment.systemPackages = with pkgs; [
      xwayland-satellite
      swaylock
      swaynotificationcenter
      brightnessctl
      playerctl
      nemo
    ];

    #
    # user-specific settings, rendered via home-manager
    #
    home-manager.users.lilly = lib.mkIf isUserEnabled {
      services.ssh-agent.enable = true;
      services.network-manager-applet.enable = true;

      gtk = {
        enable = true;
        iconTheme.package = pkgs.papirus-icon-theme;
        colorScheme = "dark";
        iconTheme.name = "Papirus";
        gtk3.extraCss = ''
          @define_color accent_color ${colors.pinkMain};
          @define_color accent_bg_color ${colors.white};
        '';
        gtk4.extraCss = homeConfig.gtk.gtk3.extraCss;
      };

      # ref: https://yalter.github.io/niri/Configuration%3A-Introduction.html
      programs.niri.settings = {
        input = {
          focus-follows-mouse = {
            enable = true;
            max-scroll-amount = "5%";
          };
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

        switch-events = {
          lid-close.action = niriActions.spawn [ "swaylock" ];
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
            { proportion = 1.0 / 3.0; }
            { proportion = 0.5; }
            { proportion = 2.0 / 3.0; }
            { proportion = 0.8; }
          ];
          default-column-width = { proportion = 0.5; };
          focus-ring = {
            width = 2;
            active = { color = colors.pinkMain; };
            inactive = { color = colors.pinkDark5; };
          };
          # struts = rec {
          #   left = 24;
          #   right = left;
          # };
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
            matches = [{ app-id="^firefox$"; title="^Picture-in-Picture$"; }];
            open-floating = true;
          }
          {
            matches = [{ app-id="^org\\.keepasxc\\.KeePassXC$"; }];
            block-out-from = "screen-capture";
          }
          {
            matches = [{ app-id="^thunderbird$"; title = "^\\d+ Reminder(s?)$"; }];
            open-floating = true;
            open-focused = true;
            open-on-workspace = null;
          }
          {
            # open some windows with 2/3 proportion by default because they dont scale well or require more space
            matches = [
              { app-id="^firefox$"; is-floating=false; }
              { app-id="^org\\.keepassxc\\.KeePassXC$"; }
              { app-id="^org\\.telegram\\.desktop$"; }
              { app-id="^Element$"; }
              { app-id="^signal$"; }
            ];
            default-column-width = { proportion = 2.0 / 3.0; };
          }
          {
            matches = [{ app-id="^thunderbird$"; }];
            open-maximized = true;
          }
          {
            matches = [{ app-id="^jetbrains-pycharm$"; title = "^Welcome to PyCharm$"; }];
            open-floating = true;
            default-column-width = { proportion = 1.0 / 3.0; };
            default-window-height = { proportion = 0.5; };
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
        ] ++ cfg.additionalWindowRules ;

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
            action = niriActions.spawn [ "swaylock" ];
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
            action = niriActions.spawn [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+" ];
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
          XF86MonBrightnessUp = {
            allow-when-locked = true;
            action = niriActions.spawn [ "brightnessctl" "set" "+10%" ];
          };
          XF86MonBrightnessDown = {
            allow-when-locked = true;
            action = niriActions.spawn [ "brightnessctl" "set" "10%-" ];
          };
          XF86AudioPrev = {
            allow-when-locked = true;
            action = niriActions.spawn [ "playerctl" "previous" ];
          };
          XF86AudioNext = {
            allow-when-locked = true;
            action = niriActions.spawn [ "playerctl" "next" ];
          };
          XF86AudioPlay = {
            allow-when-locked = true;
            action = niriActions.spawn [ "playerctl" "play-pause" ];
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

          "Mod+Ctrl+Left".action = niriActions.set-column-width "-5%";
          "Mod+Ctrl+Down".action = niriActions.set-window-height "+5%";
          "Mod+Ctrl+Up".action = niriActions.set-window-height "-5%";
          "Mod+Ctrl+Right".action = niriActions.set-column-width "+5%";

          "Mod+Comma".action = niriActions.consume-or-expel-window-left;
          "Mod+Period".action = niriActions.consume-or-expel-window-right;

          "Mod+R".action = niriActions.switch-preset-column-width;
          "Mod+Shift+R".action = niriActions.switch-preset-window-height;
          "Mod+Ctrl+R".action = niriActions.reset-window-height;
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
            modules-left = [
              "niri/workspaces"
              "niri/window"
            ];
            modules-center = [ "clock" ];
            modules-right = [
              "custom/arrow5"
              "network"
              "custom/arrow4"
              "wireplumber#sink"
              "wireplumber#source"
              "custom/arrow3"
              "power-profiles-daemon"
              "custom/arrow2"
              "tray"
              "custom/arrow1"
              "battery"
              "group/group-power"
            ];
            clock = {
              format = " {:%H:%M}";
              timezone = "Europe/Berlin";
              tooltip-format = "<tt>{calendar}</tt>";
              calendar = {
                mode = "year";
                mode-mon-col = 4;
                weeks-pos = "left";
                format = {
                  months = "<span color='${colors.white}'><b>{}</b></span>";
                  days = "<span color='${colors.pinkDark1}'><b>{}</b></span>";
                  weeks  = "<span color='${colors.blueComp}'><b>W{}</b></span>";
                  weekdays = "<span color='${colors.greenComp}'><b>{}</b></span>";
                  today = "<span color='${colors.white}'><b><u>{}</u></b></span>";
                };
              };
              actions = {
                on-click-right = "shift_reset";
              };
            };
            "network" = {
              format-ethernet = "󰈀 {ifname}";
              format-wifi = " {essid}";
              format-disconnected = "";
              tooltip-format = "{ipaddr}/{cidr}";
              on-click-right = "nm-connection-editor";
            };
            "wireplumber#sink" = {
              format = "{icon} {volume}%";
              format-muted = "󰖁";
              format-icons = [ "󰕿" "󰖀" "󰕾" ];
              node-type = "Audio/Sink";
              on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            };
            "wireplumber#source" = {
              format = "{icon} {volume}%";
              format-muted = "";
              format-icons = [ "󰍬" ];
              node-type = "Audio/Source";
              on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
            };
            power-profiles-daemon = {
              format = "{icon}";
              format-icons = {
                default = "󰓅";
                performance = "󰓅";
                balanced = "󰾅";
                power-saver = "󰾆";
              };
            };
            tray = {
              icon-size = 20;
              spacing = 10;
            };
            battery = {
              format = "{icon} {capacity}%";
              format-charging = "{icon}󱐋 {capacity}%";
              format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
            };
            "group/group-power" = {
              orientation = "inherit";
              drawer = {
                children-class = "group-power";
                transition-left-to-right = false;
              };
              modules = [
                "custom/power-menu"
                "custom/lock"
                "custom/quit"
                "custom/reboot"
                "custom/poweroff"
              ];
            };
            "custom/power-menu" = {
              format = "󰐥";
              tooltip-format = "Power Menu";
            };
            "custom/poweroff" = {
              format = "󰚥";
              tooltip-format = "Poweroff";
              on-click = "systemctl poweroff";
            };
            "custom/lock" = {
              format = "󰍁";
              tooltip-format = "Lock";
              on-click = "swaylock";
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
            "custom/arrow1" = {
              format = "";
              tooltip = false;
            };
            "custom/arrow2" = {
              format = "";
              tooltip = false;
            };
            "custom/arrow3" = {
              format = "";
              tooltip = false;
            };
            "custom/arrow4" = {
              format = "";
              tooltip = false;
            };
            "custom/arrow5" = {
              format = "";
              tooltip = false;
            };
          };
        };
        style = ''
          * {
          	border: none;
          	border-radius: 0;
          	font-family: sans-serif;
          	font-size: 11pt;
          	color: white;
          }

          window#waybar {
            background: alpha(${colors.pinkDark4}, 0.5);
          	/*background: rgba(43, 48, 59, 0.8);*/
          	/*background: alpha(#abdef5, 0.8);*/
          	border-bottom: white 1px solid;
          }

          window#waybar > .horizontal {
          	margin-bottom: 1px;
          	margin-left: 12px;
          }

          tooltip {
          	background: rgb(43, 48, 59);
          	border: 1px solid rgb(100, 114, 125);
          }

          #workspaces button:hover {
            background: rgba(0, 0, 0, 0.2);
          }

          #workspaces button.active {
              background: inherit;
              box-shadow: inset 0 -3px #ffbcff;
          }

          #workspaces button.focused {
              background-color: #64727D;
              box-shadow: inset 0 -3px #ffffff;
          }

          #workspaces button.urgent {
              /* background-color: #eb4d4b; */
              box-shadow: inset 0 -3px #eb4d4b, inset -3px 0px #eb4d4b, inset 0 3px #eb4d4b, inset 3px 0px #eb4d4b;
          }


          #clock {
          	background-color: ${colors.pinkDark1};
          	border-radius: 6px;
          	padding: 0px 10px;
          	margin: 4px 0px;
          }

          #custom-arrow5 {
            font-size: 24pt;
            color: ${colors.pinkDark5};
            background: transparent;
          }
          #network {
            padding: 0 16px;
            background: ${colors.pinkDark5};
          }

          #custom-arrow4 {
            font-size: 24pt;
            color: ${colors.pinkDark4};
            background: ${colors.pinkDark5};
          }
          #wireplumber {
            padding: 0 16px;
            background: ${colors.pinkDark4};
          }

          #custom-arrow3 {
            font-size: 24pt;
            color: ${colors.pinkDark3};
            background: ${colors.pinkDark4};
          }
          #power-profiles-daemon {
            padding-left: 16px;
            padding-right: 16px;
            color: white;
            background: ${colors.pinkDark3};
          }
          label#power-profiles-daemon {
            font-size: 14pt;
          }
          label#power-profiles-daemon.performance {
            color: lighter(red);
          }
          label#power-profiles-daemon.balanced {
            color: inherit;
          }
          label#power-profiles-daemon.power-saver {
            color: ${colors.greenComp};
          }

          #custom-arrow2 {
            font-size: 24pt;
            color: ${colors.pinkDark2};
            background: ${colors.pinkDark3};
          }
          #tray {
            padding: 0 16px;
            background: ${colors.pinkDark2};
          }
          #tray > .passive {
            -gtk-icon-effect: dim;
          }
          #tray > .needs-attention {
            -gtk-icon-effect: highlight;
          }

          #custom-arrow1 {
            font-size: 24pt;
            color: ${colors.pinkDark1};
            background: ${colors.pinkDark2};
          }
          #battery {
            padding: 0 16px;
            background: ${colors.pinkDark1};
          }
          #group-power {
            font-size: 12pt;
            background: ${colors.pinkDark1};
          }

          #custom-power-menu {
            padding-left: 6px;
            padding-right: 12px;
          }
          
          #custom-lock,
          #custom-quit,
          #custom-reboot,
          #custom-poweroff {
            font-size: 12pt;
            padding-left: 6px;
            padding-right: 6px;
            background: ${colors.pinkDark3};
            margin-top: 2px;
            margin-bottom: 2px;
            border-top: 2px solid ${colors.pinkDark3};
            border-bottom: 2px solid ${colors.pinkDark3};
          }
          #custom-lock {
            border-left: 2px solid ${colors.pinkDark3};
          }
          #custom-poweroff {
            border-right: 2px solid ${colors.pinkDark3};
          }
        '';
      };

      # lock screen
      xdg.configFile."swaylock/config".text = ''
        show-keyboard-layout
        indicator-caps-lock
        font=Inter
        image=~/Sync/Wallpapers/ccc-camp.jpg
      '';

      # configure a background image daemon
      systemd.user.services."swaybg" = {
        Unit = {
          Description = "niri background daemon";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          Type = "exec";
          ExecStart = ''
            ${lib.getExe pkgs.swaybg} \
              --image "${../dotfiles/lilly/wallpapers/dino.jpg}" \
              --output "*" \
              --mode fill
          '';
        };
        Install = {
          WantedBy = [ "niri.service" ];
        };
      };
    };
  };
}
