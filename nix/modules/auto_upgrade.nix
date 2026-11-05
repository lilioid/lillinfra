{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.custom.autoUpgrade;

  upgrade-script = pkgs.writeShellApplication {
    name = "auto-upgrade.sh";
    runtimeInputs = with pkgs; [
      switch-nixos-raw
      curl
      nix
    ];
    text = ''
      MODE=$1
      SYSTEM_CLOSURE_URL=$2

      echo "Fetching current system path from URL"
      TARGET_SYSTEM_CLOSURE=$(curl -sSLf "''${SYSTEM_CLOSURE_URL}")
      CURRENT_SYSTEM_CLOSURE=$(readlink /run/current-system)

      if [[ "''${CURRENT_SYSTEM_CLOSURE}" = "''${TARGET_SYSTEM_CLOSURE}" ]]; then
        echo "Current system closure is already at ''${CURRENT_SYSTEM_CLOSURE}"
        exit
      else
        echo "Target System closure has changed to ''${TARGET_SYSTEM_CLOSURE}"
      fi

      echo "Updating system now…"
      case "''${MODE}" in
        "live")
          switch-nixos-raw switch --diff "''${TARGET_SYSTEM_CLOSURE}" ;;

        "reboot")
          switch-nixos-raw boot --diff "''${TARGET_SYSTEM_CLOSURE}"
          systemctl reboot
          ;;
      esac
    '';
  };
in
{
  options = with lib.options; {
    custom.autoUpgrade = {
      enable = mkEnableOption "auto upgrades from my git repository";
      mode = mkOption {
        default = "live";
        description = "Whether to perform live in-place upgrades or upgrade only via reboots";
        type = lib.types.enum [
          "live"
          "reboot"
        ];
      };
      systemClosureUrl = mkOption {
        description = "URL to a file that contains this systems current closure as a path in /nix/store";
        default = "https://git.hanse.de/api/packages/lilly/generic/nix-system-${ config.networking.fqdnOrHostName }/latest/system-closure.txt";
        defaultText = "https://git.hanse.de/api/packages/lilly/generic/nix-system-<networking.fqdnOrHostName>/latest/system-closure.txt";
        type = lib.types.str;
      };
      dates = mkOption {
        description = "SystemD calendar expression on which auto-upgrade should run";
        default = "04:00";
        type = lib.types.str;
      };
      randomizedDelaySec = mkOption {
        description = "SystemD calendar RandomizedDelaySec for introducing update jitter";
        default = "1h";
        type = lib.types.str;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services."nixos-auto-upgrade" = {
      requires = [ "network.target" ];
      after = [ "network.target" "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''${lib.getExe upgrade-script} "${cfg.mode}" "${cfg.systemClosureUrl}"'';
      };
    };

    systemd.timers."nixos-auto-upgrade" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.dates;
        RandomizedDelaySec = cfg.randomizedDelaySec;
      };
    };
  };
}
