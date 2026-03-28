{ config, lib, pkgs, ... }:
let
  cfg = config.custom.hardware;
in {
  # option definitions
  options = with lib.options; {
    custom.hardware = {
      enableNitrokey = mkEnableOption "nitrokey hardware drivers and required support programs";
    };
  };

  # implementations
  config = lib.mkIf cfg.enableNitrokey {
    hardware.nitrokey.enable = true;
    services.pcscd.enable = true;

    environment.systemPackages = with pkgs; [
       nitrokey-app2
       pynitrokey
    ];
  };
}
