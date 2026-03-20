{ config, lib, ... }:
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
    hardware.gpgSmartcards.enable = true;
    hardware.nitrokey.enable = true;
    services.pcscd.enable = true;
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
}
