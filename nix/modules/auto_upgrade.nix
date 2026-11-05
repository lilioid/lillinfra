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
        echo "Target Sysdtem closure has changed to ''${TARGET_SYSTEM_CLOSURE}"
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
        RuntimeDirectory = "nixos-auto-upgrade";
      };
    };

    # system.autoUpgrade = {
    #   enable = true;
    #   flake = "git+https://git.lly.sh/lilly/lillinfra.git#${config.networking.fqdnOrHostName}";
    #   operation = if cfg.mode == "live" then "switch" else "boot";
    #   dates = "04:00";
    #   randomizedDelaySec = "30min";
    # };
  };
}
