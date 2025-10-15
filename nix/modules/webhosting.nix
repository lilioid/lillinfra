{ pkgs, lib, config, ... }:
let
  cfg = config.custom.webhosting;

  mkCtlScript = userCfg: pkgs.writeShellApplication {
    name = "webctl";
    runtimeInputs = with pkgs; [ coreutils findutils acl jq ];
    text = ''
      function info {
        echo "ssh conection: ${userCfg.name}@${config.networking.fqdnOrHostName}"
        echo "internal host: https://${userCfg.defaultDomain}/"
        echo "additional hosts: ${lib.concatStringsSep " " (lib.map (i: "https://${i}/") userCfg.domains)}"
        echo "ip addresses: $(ip --json address show scope global | jq -r '[.[].addr_info.[].local] | map(select(. != null)) | join(", ")')"
      }

      function fix {
        echo "ensuring the www directory exists"
        mkdir -p "$HOME/www"

        echo "ensuring the www directory and its files have correct permissions"
        chmod -R u=rwX "$HOME/www"
        setfacl --modify "u:${config.services.nginx.user}:x" "$HOME"
        setfacl -R --modify "default:u:${config.services.nginx.user}:rX,u:${config.services.nginx.user}:rX" "$HOME/www"
      }

      case ''${1:--help} in
        info)
          info
          ;;
        fix)
          fix
          ;;
        --help|-h|help|*)
          echo "usage: webctl [--help|info|fix]"
          echo ""
          echo "Most awesomest script for controlling the most awesomest webhosting platform made and operated by – yours truly – lilly"
          echo "Mew at me via li@lly.sh if you have problems"
          echo ""
          echo "Subcommands:"
          echo "  help         - Shows this help message"
          echo "  info         - Shows a bunch of useful information regarding your hosting setup"
          echo "  fix          - Fixes common issues with permissions of your web directory"
          exit 0
          ;;
      esac
    '';
  };
in
{
  #
  # API Declaration
  #
  options = with lib.options; with lib.types; {
    custom.webhosting = {
      openPorts = mkOption {
        description = "Whether port 80 and 443 should automatically be opened on the firewall";
        default = true;
        type = bool;
      };
      users = mkOption {
        description = "List of users who have a webhost configured";
        default = { };
        type = attrsOf (submodule (
          { config, ... }: {
            options = {
              name = mkOption {
                description = "Name of the user";
                default = config._module.args.name;
                defaultText = "key of the attrset which contains this definition";
                type = str;
              };
              sshKey = mkOption {
                description = "Public SSH key of the user";
                type = str;
              };
              shell = mkPackageOption pkgs "bash" { };
              defaultDomain = mkOption {
                description = "Internal default domain that should always be available and hosting the users content";
                type = str;
                default = "${config.name}.hosted-on.aut-sys.de";
                internal = true;
              };
              ctlScript = mkOption {
                description = "webctl derivation specific to this user";
                default = mkCtlScript config;
                internal = true;
              };
              domains = mkOption {
                description = "List of domain names which should serve the users content";
                default = [ ];
                type = listOf str;
              };
              nginxIndex = mkOption {
                description = "Value of an nginx index directive";
                default = "index.html";
                type = nullOr str;
              };
            };
          }
        ));
      };
    };
  };

  #
  # Implementation (by rendering into other NixOS options)
  #
  config = {
    # add required linux users users
    users.users = lib.attrsets.mapAttrs'
      (name: config: lib.nameValuePair config.name {
        name = config.name;
        home = "/home/${config.name}";
        shell = config.shell;
        openssh.authorizedKeys.keys = [ config.sshKey ];
        isNormalUser = true;
        packages = [ config.ctlScript ];
      })
      cfg.users;

    # add required nginx configuration
    services.nginx = {
      enable = true;
      virtualHosts = lib.attrsets.mapAttrs'
        (name: config: lib.nameValuePair config.defaultDomain {
          serverAliases = config.domains;
          root = "/home/${config.name}/www";
          forceSSL = true;
          enableACME = true;
          locations."/".index = config.nginxIndex;
        })
        cfg.users;
    };

    # configure firewall
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openPorts [
      80
      443
    ];

    # relax some security settings that would prevent nginx from reading website directories
    systemd.services.nginx.serviceConfig.ProtectHome = "read-only";
  };
}
