{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.niri;
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
    programs.niri.enable = true;
    programs.waybar.enable = true;
    qt.style = "adwaita";

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      xdgOpenUsePortal = true;
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    };

    environment.systemPackages = with pkgs; [
      swaylock
      swaynotificationcenter
    ];

    # configure a background image daemon
    systemd.user.services."swaybg" = {
      description = "niri background";
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      wantedBy = [ "niri.service" ];
      path = with pkgs; [ swaybg ];
      script = ''swaybg --image "$HOME/Sync/Wallpapers/Queer Smoke/aesthr-smoke-trans.png" --output "*"'';
    };

    fonts = {
      packages = with pkgs; [ inter nerd-fonts.jetbrains-mono ];
      fontconfig.defaultFonts = {
        sansSerif = [ "Inter" ];
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
