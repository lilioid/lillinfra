{ config, lib, pkgs, ... }:
let
  cfg = config.custom.niriDesktop;
in {
  imports = [
    ./desktop_apps.nix
  ];

  options.custom.niriDesktop = with lib.options; {
    enable = mkEnableOption "niri desktop environment";
  };

  config = lib.mkIf cfg.enable {
    programs.niri.enable = true;
    services.xserver.displayManager.gdm.enable = true;
    services.displayManager.enable = true;

    home-manager.users.lilly = {
      programs.fuzzel.enable = true;  # app launcher
      programs.waybar.enable = true;  # status bar
      programs.swaylock.enable = true;  # lock screen
      services.mako.enable = true;    # notifications
      services.swayidle.enable = true;  # automatic locking

      # TODO xdg-desktop-portals
    };

    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-gnome
      ];
    };

    environment.systemPackages = with pkgs; [
      swaybg  # background image renderer
      xwayland-satellite # be able to run x apps
      alacritty
      font-awesome
    ];

    # use inter as default font
    fonts = {
      packages = with pkgs; [ inter ];
      fontconfig.defaultFonts = {
        sansSerif = [ "Inter" ];
        emoji = [ "Noto Color Emoji" "Font Awesome" ];
      };
    };

    # audio config (use pipewire)
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
    services.pulseaudio.enable = false;
  };
}
