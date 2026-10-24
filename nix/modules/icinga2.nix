{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.icinga2;

  attrValue2icingaValue =
    value:
    if (lib.typeOf value) == "null" then
      "null"
    else if (lib.typeOf value) == "int" then
      lib.toString value
    else if (lib.typeOf value) == "float" then
      lib.toString value
    else if (lib.typeOf value) == "bool" then
      if value then "true" else "false"
    else if (lib.typeOf value) == "string" then
      "\"${value}\""
    else if (lib.typeOf value) == "list" then
      "[${lib.concatMapStringsSep ", " attrValue2icingaValue value}]"
    else if (lib.typeOf value) == "set" then
      ''
        {
            ${lib.concatMapAttrsStringSep "\n" attr2icingaProperty value}
          }
      ''
    else
      throw "unmappable value type ${lib.typeOf value}";

  attr2icingaProperty =
    key: value:
    if key == "assign where" then
      "assign where ${value}"
    else
      "${key} = ${attrValue2icingaValue value}";

  config2icingaStanza = header: value: ''
    ${header} {
      ${
        if (lib.typeOf value) == "string" then
          lib.trim value
        else
          lib.concatMapAttrsStringSep "\n  " attr2icingaProperty value
      }
    }
  '';

  mkIcingaObjectsConf =
    optionAttrs: lib.concatStringsSep "\n" (lib.mapAttrsToList config2icingaStanza optionAttrs);

  icingaStanzaOptionType = lib.types.attrsOf (
    lib.types.either (lib.types.str) (
      lib.types.attrsOf (
        lib.types.oneOf [
          lib.types.str
          lib.types.bool
          lib.types.number
          (lib.types.attrsOf lib.types.anything) # TODO: more concrete type please
          (lib.types.listOf lib.types.anything) # TODO: more concrete type please
        ]
      )
    )
  );
in
{
  options = with lib.options; {
    services.icinga2 = {
      enable = mkEnableOption "icinga2 monitoring szone2Conf ystem";
      package = mkPackageOption pkgs "icinga2" { };
      monitoringPlugins = mkPackageOption pkgs "monitoring-plugins" { };
      pki = {
        ca_key = mkOption {
          description = "Path to a ca.key file";
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        ca_crt = mkOption {
          description = "Path to a ca.crt file";
          type = lib.types.str;
        };
      };
      settings = {
        NodeName = mkOption {
          description = "NodeName constant used in the icinga2 config";
          type = lib.types.str;
          default = config.networking.fqdnOrHostName;
          defaultText = "config.networking.fqdnOrHostName";
        };
        ZoneName = mkOption {
          description = "ZoneName constant used in the icinga2 config";
          type = lib.types.str;
          default = config.networking.fqdnOrHostName;
          defaultText = "config.networking.fqdnOrHostName";
        };
        stanzas = mkOption {
          description = "icinga2 stanzas (https://icinga.com/docs/icinga-2/latest/doc/09-object-types/)";
          default = { };
          type = icingaStanzaOptionType;
        };
        zonedStanzas = mkOption {
          description = "icinga2 stanzas put into /etc/icinga2/zones.d/";
          default = { };
          type = lib.types.attrsOf icingaStanzaOptionType;
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];

    # required users and groups
    users.users = {
      "icinga2" = {
        isSystemUser = true;
        createHome = false;
        group = "icinga2";
      };
    };
    users.groups = {
      "icinga2" = { };
    };

    # render configuration
    environment.etc = {
      "icinga2/icinga2.conf".text = ''
        /**
         * Icinga 2 configuration file
         * This file is packaged from NixOS and adapted from upstream Icinga distrubted ones.
         * Definitions based on NixOS options are found in the nixos.conf file and included here.
         *
         * For an overview of all available configuration options please refer
         * to the documentation that is distributed as part of Icinga 2.
         */

        /**
         * The constants.conf defines global constants.
         */
        include "constants.conf"
        include "nixos.conf"

        /**
         * The Icinga Template Library (ITL) provides a number of useful templates
         * and command definitions.
         * Common monitoring plugin command definitions are included separately.
         */
        include <itl>
        include <plugins>

        /**
         * This includes the Icinga 2 Windows plugins. These command definitions
         * are required on a master node when a client is used as command endpoint.
         */
        include <windows-plugins>

        /**
         * This includes the NSClient++ check commands. These command definitions
         * are required on a master node when a client is used as command endpoint.
         */
        include <nscp>
      '';
      "icinga2/constants.conf".text = ''
        const NodeName = "${cfg.settings.NodeName}"
        const ZoneName = "${cfg.settings.ZoneName}"
        const PluginDir = "${cfg.monitoringPlugins}/bin"; 
      '';
      "icinga2/nixos.conf".text = mkIcingaObjectsConf cfg.settings.stanzas;
    }
    // (lib.mapAttrs' (zoneName: value: {
      name = "icinga2/zones.d/${zoneName}/objects.conf";
      value = {
        text = mkIcingaObjectsConf value;
      };
    }) cfg.settings.zonedStanzas);

    # systemd service definition for icinga2 core
    systemd.services."icinga2" = {
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        "User" = "icinga2";
        "Group" = "icinga2";
        "SupplementaryGroups" = "redis-icingadb";
        "RuntimeDirectory" = "icinga2";
        "StateDirectory" = "icinga2";
        "StateDirectoryMode" = "0750";
        "ConfigurationDirectory" = "icinga2";
        "ConfigurationDirectoryMode" = "0550";
        "CacheDirectory" = "icinga2";
        "ExecStart" = "${lib.getExe' cfg.package "icinga2"} daemon";
        "ExecReload" = "${lib.getExe' pkgs.coreutils "kill"} -HUP $MAINPID";
      };
    };
  };
}
