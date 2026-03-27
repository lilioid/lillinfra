{
  config,
  lib,
  pkgs,
  noctalia,
  ...
}:
let
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
in
{
  imports = [
    ./desktop_apps.nix
  ];

  # option definitions
  options = with lib.options; {
    custom.niri = {
      enable = mkEnableOption "a configured niri desktop environment";
      configOverride = mkOption {
        description = "Niri configuration overrides";
        default = { };
        type = lib.types.attrsOf lib.types.attrs;
      };
      additionalWindowRules = mkOption {
        description = "Additional window-rules to add without overriding existing ones";
        default = [ ];
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
    services.upower.enable = true;
    services.gvfs.enable = true;

    # configure my preferred system fonts
    fonts = {
      packages = with pkgs; [
        inter
        maple-mono.variable
        nerd-fonts.symbols-only
      ];
      fontconfig.defaultFonts = {
        sansSerif = [
          "Symbols Nerd Font"
          "Inter"
        ];
        monospace = [
          "Maple Mono"
          "Symbols Nerd Font Mono"
        ];
      };
    };

    # configure desktop portals to use standard gtk portal (which is recommended by niri)
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      xdgOpenUsePortal = true;
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    };

    # enable pipewire audio handling with compatibility layers
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    # enable a DisplayManager
    services.displayManager.enable = true;
    services.displayManager.gdm.enable = true;

    environment.systemPackages = with pkgs; [
      xwayland-satellite
      nemo # standard file manager
      nautilus # needed for "open file" dialogs
      loupe
      trash-cli
      wl-mirror
    ];

    #
    # user-specific settings rendered via home-manager
    #
    home-manager.users.lilly = lib.mkIf isUserEnabled {
      imports = [
        noctalia.homeModules.default
      ];

      services.ssh-agent.enable = true;

      programs.noctalia-shell = {
        enable = true;
        settings = {
          bar = {
            barType = "simple";
            position = "top";
            density = "default";
            showOutline = false;
            showCapsule = true;
            widgetSpacing = 6;
            contentPadding = 2;
            enableExclusionZoneInste = false;
            marginVertical = 4;
            marginHorizontal = 4;
            frameThickness = 8;
            frameRadius = 12;
            outerCorners = false;
            hideOnOverview = false;
            displayMode = "always_visible";
            widgets = {
              left = [
                {
                  id = "Workspace";
                  enableScrollWheel = true;
                  labelMode = "index";
                  occupiedColor = "none";
                  focusedColor = "primary";
                  showApplications = false;
                }
                {
                  id = "Clock";
                  formatHorizontal = "HH:mm ddd, dd.MM.yyyy";
                }
                {
                  id = "SystemMonitor";
                  showCpuUsage = true;
                  showMemoryUsage = true;
                  compactMode = false;
                  usePadding = true;
                }
              ];
              center = [
                {
                  id = "ActiveWindow";
                  useFixedWidth = true;
                }
              ];
              right = [
                {
                  id = "MediaMini";
                }
                {
                  id = "Tray";
                  drawerEnabled = false;
                }
                {
                  id = "NotificationHistory";
                }
                {
                  id = "Battery";
                  displayMode = "icon-always";
                  hideIfNotDetected = true;
                  showPowerProfiles = true;
                }
                {
                  id = "Volume";
                  displayMode = "alwaysShow";
                }
                {
                  id = "Brightness";
                  displayMode = "alwaysShow";
                }
                {
                  id = "Bluetooth";
                }
                {
                  id = "Network";
                  displayMode = "alwaysShow";
                }
                {
                  id = "ControlCenter";
                }
              ];
            };
          };
          general = {
            avatarImage = "/home/lilly/Sync/ProfilePictures/poly_fox.jpg";

          };
          location = {
            name = "Hamburg";
          };
          wallpaper = {
            directory = "/home/lilly/Sync/Wallpapers";
            viewMode = "browse";
            setWallpaperOnAllMonitors = true;
          };
          appLauncher = {
            enableClipboardHistory = false;
            terminalCommand = "kitty -e";
            enableSettingsSearch = false;
            enableSessionSearch = false;
          };
          controlCenter = {
            shortcuts = {
              left = [
                { id = "Network"; }
                { id = "Bluetooth"; }
                { id = "PowerProfile"; }
              ];
              right = [
                { id = "Notifications"; }
                { id = "KeepAwake"; }
                { id = "NightLight"; }
                { id = "DarkMode"; }
              ];
            };
            cards = [
              {
                id = "profile-card";
                enabled = true;
              }
              {
                id = "shortcuts-card";
                enabled = true;
              }
              {
                id = "audio-card";
                enabled = true;
              }
              {
                id = "brightness-card";
                enabled = true;
              }
              {
                id = "weather-card";
                enabled = true;
              }
              {
                id = "media-sysmon-card";
                enabled = true;
              }
            ];
          };
          dock = {
            enabled = false;
          };
          desktopWidgets = {
            enabled = false;
          };
          sessionMenu = {
            showKeybinds = false;
            largeButtonsStyle = false;

          };
          idle = {
            enabled = true;
            suspendTimeout = 0; # disable auto-suspend
          };
          colorSchemes = {
            predefinedScheme = "Rose Pine";
            darkMode = false;
          };
        };
      };

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
        spawn-at-startup = [
          { command = [ "noctalia-shell" ]; }
        ];

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
            tap = true;
            dwt = true;
            drag = true;
            natural-scroll = true;
            accel-speed = 0.1;
            accel-profile = "adaptive";
            left-handed = true;
            scroll-method = "two-finger";
            scroll-factor = 0.8;
          };
          mouse = { };
          trackpoint = { };
        };

        switch-events = {
          lid-close.action = niriActions.spawn [ "noctalia-shell" "ipc" "call" "sessionMenu" "lock" ];
        };

        outputs = { }; # override this via the configOverride option

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
          default-column-width = {
            proportion = 0.5;
          };
          focus-ring = {
            width = 2;
            active = {
              color = colors.pinkMain;
            };
            inactive = {
              color = colors.pinkDark5;
            };
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
            # hide certain apps from screen capture
            matches = [
              { app-id = "^signal$"; }
              { app-id = "^Element$"; }
              { app-id = "^org.telegram.desktop$"; }
              { app-id = "^org.gnome.Evolution$"; }
              { app-id = "^thunderbird$"; }
              { app-id = "^org.keepassxc.KeePassXC"; }
              { app-id = "^org\\.keepasxc\\.KeePassXC$"; }
            ];
            block-out-from = "screen-capture";
          }
          {
            matches = [
              {
                app-id = "^firefox$";
                title = "^Picture-in-Picture$";
              }
            ];
            open-floating = true;
          }
          {
            matches = [
              {
                app-id = "^thunderbird$";
                title = "^\\d+ Reminder(s?)$";
              }
            ];
            open-floating = true;
            open-focused = true;
            open-on-workspace = null;
          }
          {
            # open some windows with 2/3 proportion by default because they dont scale well or require more space
            matches = [
              {
                app-id = "^firefox$";
                is-floating = false;
              }
              { app-id = "^org\\.keepassxc\\.KeePassXC$"; }
              { app-id = "^org\\.telegram\\.desktop$"; }
              { app-id = "^Element$"; }
              { app-id = "^signal$"; }
            ];
            default-column-width = {
              proportion = 2.0 / 3.0;
            };
          }
          {
            matches = [
              { app-id = "^thunderbird$"; }
              {
                app-id = "^org.gnome.Evolution$";
                title = "^Mail|Inbox$";
              }
            ];
            open-maximized = true;
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
        ]
        ++ cfg.additionalWindowRules;

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
            action = niriActions.spawn [
              "noctalia-shell"
              "ipc"
              "call"
              "launcher"
              "toggle"
            ];
          };
          "Mod+L" = {
            hotkey-overlay.title = "Lock the Screen";
            repeat = false;
            action = niriActions.spawn [
              "noctalia-shell"
              "ipc"
              "call"
              "sessionMenu"
              "lock"
            ];
          };
          "Mod+Dead_Circumflex" = {
            hotkey-overlay.title = "Toggle Notification-Center";
            action = niriActions.spawn [
              "noctalia-shell"
              "ipc"
              "call"
              "notifications"
              "toggleHistory"
            ];
          };
          "Mod+Shift+Dead_Circumflex" = {
            hotkey-overlay.title = "Toggle DnD";
            action = niriActions.spawn [
              "noctalia-shell"
              "ipc"
              "call"
              "notifications"
              "toggleDND"
            ];
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
            hotkey-overlay.title = "Open File Browser";
            repeat = false;
            action = niriActions.spawn [ "nemo" ];
          };
          "Mod+Shift+D" = {
            hotkey-overlay.title = "Open Emoji Picker";
            repeat = false;
            action = niriActions.spawn [
              "noctalia-shell"
              "ipc"
              "call"
              "launcher"
              "emoji"
            ];
          };
          "XF86AudioRaiseVolume" = {
            allow-when-locked = true;
            action = niriActions.spawn [
              "wpctl"
              "set-volume"
              "@DEFAULT_AUDIO_SINK@"
              "0.1+"
            ];
          };
          "XF86AudioLowerVolume" = {
            allow-when-locked = true;
            action = niriActions.spawn [
              "wpctl"
              "set-volume"
              "@DEFAULT_AUDIO_SINK@"
              "0.1-"
            ];
          };
          "XF86AudioMute" = {
            allow-when-locked = true;
            action = niriActions.spawn [
              "wpctl"
              "set-mute"
              "@DEFAULT_AUDIO_SINK@"
              "toggle"
            ];
          };
          "XF86AudioMicMute" = {
            allow-when-locked = true;
            action = niriActions.spawn [
              "wpctl"
              "set-mute"
              "@DEFAULT_AUDIO_SOURCE@"
              "toggle"
            ];
          };
          XF86MonBrightnessUp = {
            allow-when-locked = true;
            action = niriActions.spawn [
              "noctalia-shell"
              "ipc"
              "call"
              "brightness"
              "increase"
            ];
          };
          XF86MonBrightnessDown = {
            allow-when-locked = true;
            action = niriActions.spawn [
              "noctalia-shell"
              "ipc"
              "call"
              "brightness"
              "decrease"
            ];
          };
          XF86AudioPrev = {
            allow-when-locked = true;
            action = niriActions.spawn [
              "noctalia-shell"
              "ipc"
              "call"
              "media"
              "previous"
            ];
          };
          XF86AudioNext = {
            allow-when-locked = true;
            action = niriActions.spawn [
              "noctalia-shell"
              "ipc"
              "call"
              "media"
              "next"
            ];
          };
          XF86AudioPlay = {
            allow-when-locked = true;
            action = niriActions.spawn [
              "noctalia-shell"
              "ipc"
              "call"
              "media"
              "playPause"
            ];
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
          "Print".action.screenshot = { };
          "Ctrl+Alt+Delete".action = niriActions.spawn [ "noctalia-shell" "ipc" "call" "sessionMenu" "toggle" ];
        };
      }
      // cfg.configOverride;
    };
  };
}
