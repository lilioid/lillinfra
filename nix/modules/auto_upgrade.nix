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
      jq
      git
      nix
    ];
    text = ''
      MODE=$1
      GIT_REPO=$2
      SYSTEMS_FILE=$3
      OWN_SYSTEM_NAME=$4
      STATE_DIR=/run/nixos-auto-upgrade
      GIT_DIR="''${STATE_DIR}/git"

      cd "$STATE_DIR"
      git clone --depth=1 "''${GIT_REPO}" "''${GIT_DIR}"

      echo "Parsing system path from git repo"
      SYSTEM_CLOSURE=$(jq -r <"''${GIT_DIR}/''${SYSTEMS_FILE}" ".[\"''${OWN_SYSTEM_NAME}\"]")
      CURRENT_SYSTEM_CLOSURE=$(readlink /run/current-system)

      if [[ "''${CURRENT_SYSTEM_CLOSURE}" = "''${SYSTEM_CLOSURE}" ]]; then
        echo "Current system closure is already at ''${CURRENT_SYSTEM_CLOSURE}"
        # exit
      else
        echo "System closure has changed to ''${SYSTEM_CLOSURE}:"
        nix --extra-experimental-features nix-command store --quiet diff-closures "''${CURRENT_SYSTEM_CLOSURE}" "''${SYSTEM_CLOSURE}"
      fi

      echo "Updating now…"
      case "''${MODE}" in
        "live")
          switch-nixos-raw switch "''${SYSTEM_CLOSURE}" ;;

        "reboot")
          switch-nixos-raw boot "''${SYSTEM_CLOSURE}"
          systemctl reboot
          ;;
      esac
    '';
  };
in
{
  options = {
    custom.autoUpgrade = {
      enable = lib.options.mkEnableOption "auto upgrades from my git repository";
      mode = lib.options.mkOption {
        default = "live";
        description = "Whether to perform live in-place upgrades or upgrade only via reboots";
        type = lib.types.enum [
          "live"
          "reboot"
        ];
      };
      git = lib.options.mkOption {
        description = "URL of my git repository which tracks all system definitions";
        default = "https://git.hanse.de/lilly/lillinfra.git";
        type = lib.types.str;
      };
      systemsFile = lib.options.mkOption {
        description = "Path to a file inside my git repository which knows current system closure paths of all systems";
        default = "nix/system-closures.json";
        type = lib.types.str;
      };
      systemName = lib.options.mkOption {
        description = "Name of this system that shall be used when querying the systemsFile";
        default = config.networking.fqdnOrHostName;
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
        ExecStart = ''${lib.getExe upgrade-script} "${cfg.mode}" "${cfg.git}" "${cfg.systemsFile}" "${cfg.systemName}"'';
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
