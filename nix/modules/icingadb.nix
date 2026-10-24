{ config, pkgs, lib, ... }:
let
  cfg = config.services.icingadb;
  toYaml = lib.generators.toYAML {};
in {
  options = with lib.options; {
    services.icingadb = {
      enable = mkEnableOption "icingadb daemon";
      package = mkPackageOption pkgs "icingadb" {};
      settings = mkOption {
        default = {};
        description = "Values for the icingdb configuration. See https://icinga.com/docs/icinga-db/latest/doc/03-Configuration/";
        type = lib.types.attrsOf lib.types.anything;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # rendered configuration file
    environment.etc."icingadb/config.yml".text = toYaml cfg.settings;
    
    # required users and groups
    users.users = {
      "icingadb" = {
        isSystemUser = true;
        createHome = false;
        group = "icingadb";
      };
    };
    users.groups = {
      "icingadb" = { };
    };

    # systemd units
    systemd.services."icingadb" = {
      wants = [ "redis-icingadb.service" "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        "User" = "icingadb";
        "Group" = "icingadb";
        "SupplementaryGroups" = "redis-icingadb";
        # "RuntimeDirectory" = "icinga2";
        # "StateDirectory" = "icinga2";
        # "StateDirectoryMode" = "0750";
        "ConfigurationDirectory" = "icingadb";
        "ConfigurationDirectoryMode" = "0550";
        # "CacheDirectory" = "icinga2";
        "ExecStart" = "${lib.getExe cfg.package} --database-auto-import --database-schema-dir=${cfg.package}/share/schema/";
      };
    };
  };
}
