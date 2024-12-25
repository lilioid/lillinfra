{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./desktop_apps.nix
  ];

  options = {
    custom.gnomeDesktop.enable = lib.options.mkEnableOption "gnome desktop environment with my custom config";
  };

  config = lib.mkIf config.custom.gnomeDesktop.enable {
    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    services.displayManager.enable = true;

    fonts = {
      packages = with pkgs; [ inter ];
      fontconfig.defaultFonts = {
        sansSerif = [ "Inter" ];
      };
    };

    home-manager.users.ftsell = {
      dconf = with lib.gvariant; {
        enable = true;
        settings = {
          "org/gnome/desktop/interface" = {
            enable-hot-corners = true;
            show-battery-percentage = true;
            font-name = "Inter 11";
            document-font-name = "Inter 11";
          };
          "org/gnome/desktop/media-handling" = {
            automount = false;
            automount-open = false;
          };
          "org/gnome/desktop/input-sources" = {
            sources = [
              (mkTuple [
                "xkb"
                "de"
              ])
              (mkTuple [
                "xkb"
                "de+neo"
              ])
            ];
          };
          "org/gnome/mutter" = {
            edge-tiling = true;
            dynamic-workspaces = true;
          };
          "org/gnome/desktop/wm/preferences" = {
            button-layout = "appmenu:minimize,close";
            focus-mode = "mouse";
          };
          "org/gnome/shell" = {
            favorite-apps = [
              "org.gnome.Nautilus.desktop"
              "org.keepassxc.KeePassXC.desktop"
              "thunderbird.desktop"
              "signal-desktop.desktop"
              "firefox.desktop"
              "org.wezfurlong.wezterm.desktop"
            ];
          };
          "org/gnome/Console" = {
            theme = "auto";
          };
          "org/gnome/nautilus/preferences" = {
            "default-folder-viewer" = "list-view";
          };
        };
      };
    };

    environment.systemPackages = with pkgs; [
      gnome-tweaks
      gnomeExtensions.appindicator
      gnomeExtensions.caffeine
      gnomeExtensions.vitals
    ];

    environment.gnome.excludePackages = (
      with pkgs;
      [
        gnome-photos
        gnome-tour
        cheese
        gnome-music
        gnome-terminal
        gnome-calendar
        epiphany
        geary
        gnome-characters
        totem
        tali
        iagno
        hitori
        atomix
      ]
    );

    services.udev.packages = with pkgs; [ gnome-settings-daemon ];

    # audio config (use pipewire)
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
    hardware.pulseaudio.enable = false;
  };
}
