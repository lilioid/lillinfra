{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.custom.gnomeDesktop.enable {
    environment.variables = {
      "XCURSOR_THEME" = "Adwaita";
    };
    
    # fix has already been merged but not yet packaged in nixos
    nixpkgs.config.permittedInsecurePackages = [
      "cinny-4.2.3"
      "cinny-desktop-4.2.3"
      "cinny-unwrapped-4.2.3"
    ];
    environment.systemPackages = with pkgs; [
      chromium
      element-desktop
      telegram-desktop
      signal-desktop
      cinny-desktop
      whatsapp-for-linux
      nextcloud-client
      keepassxc
      wl-clipboard
      thunderbird
      spotify
      drawio
      discord
      vlc
      obsidian
      okular
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
