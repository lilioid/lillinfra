{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.custom.user-syncthing;
in
{
  options = {
    custom.user-syncthing = {
      enable = mkEnableOption "this host to be a syncthing peer";
    };
  };

  config = {
    services.syncthing = lib.mkIf cfg.enable {
      enable = true;
      group = "users";
      user = "lilly";
      dataDir = "/home/lilly/";
      settings.options.urAccepted = -1;
      openDefaultPorts = lib.mkDefault false;
      overrideFolders = false;
      overrideDevices = false;
    };

    environment.systemPackages = mkIf config.services.xserver.enable [ pkgs.syncthingtray ];
  };
}
