{ config, lib, pkgs, ... }:
let
  cfg = config.custom.greeter;
in
{
  # interface
  options = with lib.options; {
    custom.greeter = {
      enable = mkEnableOption "greetd with configuration";
    };
  };

  # implemenation
  config = lib.kmIf cfg.enable {
    services.greetd = {
      enable = true;
      useTextGreeter = true;
      settings = {
        terminal.vt = 1;
        default_session = {
          user = "lilly";
          command = lib.getExe' pkgs.tuigreet "tuigreet";
        };
      };
    };
  };
}
