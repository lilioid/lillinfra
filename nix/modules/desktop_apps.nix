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
      discord
      vlc
      kdePackages.okular
      wezterm
      kitty
      gimp
      obsidian
      gnome-font-viewer
    ];

    services.gnome.evolution-data-server.enable = true;
    programs.evolution.enable = true;
    programs.firefox = {
      enable = true;
      preferences = {
        "browser.ml.enable" = false;
        "browser.ml.chat.enable" = false;
        "browser.ml.chat.hideFromLabs" = true;
        "browser.ml.chat.hideLabsShortcuts" = true;
        "browser.ml.chat.page" = false;
        "browser.ml.chat.page.footerBadge" = false;
        "browser.ml.chat.page.menuBadge" = false;
        "browser.ml.linkPreview.enabled" = false;
        "browser.ml.pageAssist.enabled" = false;
        "browser.tabs.groups.smart.enabled" = false;
        "browser.tabs.groups.smart.userEnable" = false;
        "extensions.ml.enabled" = false;
      };
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
