{ pkgs, config, lib, ... }:
let
  cfg = config.custom.kde;
in {
  imports = [
    ./desktop_apps.nix
  ];

  options.custom.kde = with lib.options; {
    enable = mkEnableOption "kde desktop environment with my custom config";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;

    services.desktopManager.plasma6.enable = true;
    services.displayManager = {
      enable = true;
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    };

    fonts = {
      packages = with pkgs; [ inter ];
      fontconfig.defaultFonts = {
        sansSerif = [ "Inter" ];
      };
    };

    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita";
    };

    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      #plasma-browser-integration
      konsole
      elisa
    ];
     
    # audio config (use pipewire)
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
    services.pulseaudio.enable = false;
  };
}
