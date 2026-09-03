{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeConfig = config.home-manager.users.lilly;
  cfg = config.custom.niri;
  isUserEnabled = config.custom.user.enable;
in
{
  imports = [
    ./desktop_apps.nix
  ];

  # option definitions
  options = with lib.options; {
    custom.sway = {
      enable = mkEnableOption "a configured sway desktop environment";
      # configOverride = mkOption {
      #   description = "Niri configuration overrides";
      #   default = { };
      #   type = lib.types.attrsOf lib.types.attrs;
      # };
      # additionalWindowRules = mkOption {
      #   description = "Additional window-rules to add without overriding existing ones";
      #   default = [ ];
      #   type = lib.types.listOf lib.types.attrs;
      # };
    };
  };

  # implementation
  config = lib.mkIf cfg.enable {
    #
    # general system configuration
    #
    custom.desktopApps.enableCommon = true;
    qt.style = "adwaita";
    services.gvfs.enable = true;

    # noctalia requirements
    networking.networkmanager.enable = true;
    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;

    # use gnome-keyring but only for secret management. ssh-agent is running independently
    services.gnome.gnome-keyring.enable = true;
    services.gnome.gcr-ssh-agent.enable = false;

    # configure my preferred system fonts
    # fonts = {
    #   packages = with pkgs; [
    #     inter
    #     maple-mono.variable
    #     nerd-fonts.symbols-only
    #   ];
    #   fontconfig.defaultFonts = {
    #     sansSerif = [
    #       "Symbols Nerd Font"
    #       "Inter"
    #     ];
    #     monospace = [
    #       "Maple Mono"
    #       "Symbols Nerd Font Mono"
    #     ];
    #   };
    # };

    # configure desktop portals to use standard gtk portal (which is recommended by niri)
    # TODO
    # xdg.portal = {
    #   enable = true;
    #   wlr.enable = true;
    #   xdgOpenUsePortal = true;
    #   extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    # };

    # enable pipewire audio handling with compatibility layers
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    # enable a DisplayManager
    # services.displayManager.gdm.enable = true;
    services.displayManager.ly.enable = true;

    environment.systemPackages = with pkgs; [
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
      services.ssh-agent.enable = true;
      home.sessionVariables.SSH_AUTH_SOCK = "/run/user/1000/ssh-agent";

      # set icon theme for gtk
      # crucially, this only renders ~/.config/gtk-4.0/settings.ini so that theming can still be done from noctalia
      # gtk = {
      #   enable = true;
      #   iconTheme.package = pkgs.papirus-icon-theme;
      #   iconTheme.name = "Papirus";
      # };

      # configure sway
      wayland.windowManager.sway = {
        enable = true;
        config = {
          startup = [
            { command = "noctalia"; }
          ];

          # disable all bars because I use noctalia
          bars = [ ];
          terminal = "ghostty";
          menu = "noctalia msg panel-toggle launcher";
          modifier = "Mod4";

          # TODO: set floating_modifier to $mod normal

          # TODO: switch events should lock noctalia
          # lid-close.action = niriActions.spawn [ "noctalia" "msg" "session" "lock-and-suspend" ];
          fonts.names = [ "Maple Mono" ];

          keybindings =
            let
              mod = homeConfig.wayland.windowManager.sway.config.modifier;
            in
            lib.mkOptionDefault {
              "Ctrl+Alt+Delete" = "exec noctalia msg panel-toggle session";
              "${mod}+i" = "exec xdg-open ~";
              "${mod}+l" = "exec noctalia msg session lock";
              "${mod}+Dead_Circumflex" = "exec noctalia noctalia msg panel-toggle control-center notifications";
              "${mod}+Shift+Dead_Circumflex" = "exec noctalia msg notifications-dnd-toggle";
              # TODO: "Print" = "exec noctalia screenshot or grim"

              # multimedia
              "XF86AudioRaiseVolume" = "exec noctalia msg volume-up";
              "XF86AudioLowerVolume" = "exec noctalia msg volume-down";
              "XF86AudioMute" = "exec noctalia msg volume-mute";
              "XF86AudioMicMute" = "exec noctalia msg mic-mute";
              "XF86MonBrightnessUp" = "exec noctalia msg brightness-up";
              "XF86MonBrightnessDown" = "exec noctalia msg brightness-down";
              "XF86AudioPrev" = "exec noctalia msg media previous";
              "XF86AudioNext" = "exec noctalia msg media next";
              "XF86AudioPlay" = "exec noctalia msg media play";

              # unset exit keybind which I don't want
              "${mod}+Shift+e" = null;
            };

          bindswitches."lid:on".action = "exec noctalia session lock-and-suspend";

          input = {
            "type:keyboard" = {
              xkb_layout = "de";
            };
            "type:touchpad" = {
              natural_scroll = "enabled";
              tap = "enabled";
            };
          };
          output = {
            "eDP-1" = {
              scale = "1.5";
            };
          };
        };
      };
    };
  };
}
