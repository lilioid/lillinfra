{ lib
, pkgs
, config
, ...
}:
let
  cfg = config.custom.backup;

  # utility function to filter an AttrSet to only include the members who have their .enable attr set to true
  filterEnabled = lib.attrsets.filterAttrs (_: i: i.enable);
in
{
  imports = [ ];

  options = with lib; {
    custom.backup = {
      enable = mkEnableOption "automatic backup creation";
      backupDirectories = mkOption {
        type = types.listOf types.str;
        description = "A list of directories from this host that should be backed up";
        default = [
          "/home"
          "/root"
          "/srv"
        ];
      };
      settings = mkOption {
        description = "Additional settings to apply to the borgmatic configuration";
        type = types.attrs;
        default = { };
      };
      secretNamespace = mkOption {
        description = "Name of the sops secret block that contains backup secrets";
        default = "backup";
        defaultText = "backup/<name>";
        type = types.str;
      };
      sshUser = mkOption {
        description = "Username for logging into the backup destination";
        type = types.str;
      };
      #      backupPostgres = mkOption {
      #        default = config.services.postgresql.enable;
      #        defaultText = "services.postgresql.enable";
      #        description = "Whether to enable automatic backups of postgresql databases";
      #        type = types.bool;
      #      };
      destinations = mkOption {
        description = "Definition of destination to which backups should be sent";
        default = [ ];
        type = lib.types.attrsOf (types.submodule ({ config, ... }: {
          options = {
            enable = mkOption {
              description = "Whether to enable this backup destination";
              default = true;
              type = types.bool;
            };
            path = mkOption {
              description = ''
                Destination to backup to.

                See the [Borgmatic Repository Documentation](https://torsion.org/borgmatic/reference/configuration/repositories/) for the syntax and valid values of the `path` attribute.
              '';
              type = types.str;
            };
            label = mkOption {
              description = "Label to assign to this backup destination in borgmatic";
              default = config._module.args.name;
              defaultText = "<name>";
              type = types.str;
            };
          };
        }));
      };
    };
  };

  # TODO: Enable postgres backups
  config = lib.mkIf cfg.enable {
    # configure borgmatic
    services.borgmatic = {
      enable = true;
      settings = {

        repositories = (lib.map
          (iDestination: {
            path = iDestination.path;
            label = iDestination.label;
          })
          (lib.attrValues (filterEnabled cfg.destinations)));

        source_directories = cfg.backupDirectories;
        one_file_system = true;
        exclude_patterns = [
          "/home/*/.rustup/toolchains"
          "/home/*/.vim/undodir"
          "/home/*/.local/share/containers"
          "/home/*/.local/share/virtualenv"
          "/home/*/.local/share/virtualenvs"
          "/home/*/.local/share/JetBrains/Toolbox/apps/"
          "/home/*/.local/share/Steam/"
          "/home/*/.nv/"
          "/home/*/.local/share/uv/"
          "/home/*/Downloads"
          "/home/*/Games"
          "/home/*/.cache"
          "/home/*/.local/share/Trash"
          "/home/*/.local/share/pnpm/store"
          "/home/*/.npm"
          "/home/*/.docker/"
          "/home/*/Projects/**/target/"
          "/home/*/Projects/**/.venv/"
          "/home/*/Projects/**/.terraform/"
          "/root/.cache"
          "**/node_modules/"
          "**/cache/"
          "**/Cache/"
          "**/*.cache"
        ];
        exclude_if_present = [
          ".nobackup"
        ];
        relocated_repo_access_is_ok = true;
        keep_hourly = 48;
        keep_daily = 7;
        keep_weekly = 8;

        encryption_passphrase = "{credential file ${config.sops.secrets."${cfg.secretNamespace}/repoPass".path}}";
        ssh_command = "ssh -i ${config.sops.secrets."${cfg.secretNamespace}/sshKey".path} -o StrictHostKeyChecking=no";
        verbosity = 1;
        remote_path = "borg14"; # requried for rsync.net
        extra_borg_options = {
          create = "--list --filter=AME";
        };

        # configure notifications via ntfy
        ntfy = {
          server = "https://ntfy.lly.sh";
          topic = "backups";
          access_token = "{credential file ${config.sops.secrets."${cfg.secretNamespace}/ntfyToken".path}}";
          states = [ "start" "finish" "fail" ];
          start = {
            title = "Backup started";
            message = "${config.networking.fqdnOrHostName} has started its scheduled backup";
            priority = "min";
            tags = "card_file_box";
          };
          finish = {
            title = "Backup finished";
            message = "${config.networking.fqdnOrHostName} has successfully finished its scheduled backup";
            priority = "min";
            tags = "heavy_check_mark";
          };
          fail = {
            title = "Backup failed";
            message = "${config.networking.fqdnOrHostName} failed to backup its data";
            priority = "default";
            tags = "rotating_light";
          };
        };

        #        postgresql_databases = lib.mkIf cfg.rsync-net.backupPostgres [
        #          {
        #            name = "all";
        #            format = "directory";
        #            psql_command = with pkgs; "${postgresql}/bin/psql";
        #            pg_dump_command = with pkgs; "${postgresql}/bin/pg_dump";
        #          }
        #        ];
      } // cfg.settings;
    };

    # configure sops secrets with backup credentials
    sops.secrets = {
      "${cfg.secretNamespace}/sshKey" = { };
      "${cfg.secretNamespace}/repoPass" = { };
      "${cfg.secretNamespace}/ntfyToken" = { };
    };
  };
}

