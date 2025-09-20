{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.desktopApps;
in {
  options = with lib.options; {
    custom.desktopApps = {
      enableCommon = mkEnableOption "common desktop apps";
    };
  };

  config = lib.mkIf cfg.enableCommon {
    environment.systemPackages = with pkgs; [
      chromium
      element-desktop
      telegram-desktop
      signal-desktop
      keepassxc
      wl-clipboard
      thunderbird
      spotify
      drawio
      discord
      vlc
      obsidian
      kdePackages.okular
      wezterm
      gimp
    ];

    programs.firefox = {
      enable = true;
      policies = {
        DisableTelemetry = true;
        DisablePocket = true;
        NoDefaultBookmarks = true;
        PasswordManagerEnabled = false;
        ExtensionSettings = {
          "uBlock0@raymondhill.net" = {
            installation_mode = "normal_installed";
          };
          "CookieAutoDelete@kennydo.com" = {
            installation_mode = "normal_installed";
          };
          "keepassxc-browser@keepassxc.org" = {
            installation_mode = "normal_installed";
          };
          "idcac-pub@guus.ninja" = {
            installation_mode = "normal_installed";
          };
        };
      };
    };

  };
}
