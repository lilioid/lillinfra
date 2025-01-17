{ lib, config, ... }:
let
  cfg = config.custom.autoUpgrade;
in
{
  options = {
    custom.autoUpgrade = {
      enable = lib.options.mkEnableOption "auto upgrades from my forgejo flake";
      mode = lib.options.mkOption {
        default = "live";
        description = "Whether to perform live in-place upgrades or upgrade only via reboots";
        type = lib.types.enum [
          "live"
          "reboot"
        ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    system.autoUpgrade = {
      enable = true;
      flake = "git+https://git.lly.sh/lilly/lillinfra.git#${config.networking.fqdnOrHostName}";
      operation = if cfg.mode == "live" then "switch" else "boot";
      dates = "04:00";
      randomizedDelaySec = "30min";
    };
  };
}
