{ config, lib, ... }:
let
  cfg = config.custom.gaming;
in
{
  # api
  options.custom.gaming = with lib.options; {
    enable = mkEnableOption "gaming software";
  };

  # implementation
  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      gamescopeSession.enable = true;
    };
  };
}
