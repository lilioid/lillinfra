{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.custom.backup;

  # utility function to filter an AttrSet to only include the members who have their .enable attr set to true
  filterEnabled = lib.attrsets.filterAttrs (_: i: i.enable);

  # seconds to $something conversion helpers
  minutes = 60;
  hours = 60 * minutes;
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
      backupPostgres = mkOption {
        default = config.services.postgresql.enable;
        defaultText = "services.postgresql.enable";
        description = "Whether to enable automatic backups of postgresql databases";
        type = types.bool;
      };
      notify = mkOption {
        default = "on-failure";
        description = "In which cases a notification should be sent via ntfy";
        type = types.enum [ "always" "on-failure" "never" ];
      };
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
          "/home/*/.config/heroic"
          "/home/*/.local/share/containers"
          "/home/*/.local/share/virtualenv"
          "/home/*/.local/share/virtualenvs"
          "/home/*/.local/share/JetBrains/Toolbox/apps/"
          "/home/*/.local/share/Steam/"
          "/home/*/.local/share/umu"
          "/home/*/.nv/"
          "/home/*/.local/share/uv/"
          "/home/*/.local/share/docker/"
          "/home/*/Downloads"
          "/home/*/Games"
          "/home/*/go"
          "/home/*/.cache"
          "/home/*/.local/share/Trash"
          "/home/*/.local/share/pnpm/store"
          "/home/*/.npm"
          "/home/*/.docker/"
          "/home/*/Projects/**/target/"
          "/home/*/Projects/**/.venv/"
          "/home/*/Projects/**/.terraform/"
          "/home/*/.gtkrc-2.0"
          "/home/*/.manpath"
          "/home/*/.pulse-cookie"
          "/home/*/.steampath"
          "/home/*/.steampid"
          "/home/*/.nix-defexpr"
          "/home/*/.nix-profile"
          "/home/*/.nv"
          "/home/*/.ansible"
          "/home/*/.cargo"
          "/home/*/.gnupg"
          "/home/*/.icons"
          "/home/*/.ipython"
          "/home/*/.kube"
          "/home/*/.mono"
          "/home/*/.pki"
          "/home/*/.rustup"
          "/home/*/.ssh"
          "/home/*/.steam"
          "/home/*/.terraform.d"
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
        lock_wait = 1 * hours;
        keep_daily = 7;
        keep_weekly = 8;

        encryption_passphrase = "{credential file ${config.sops.secrets."${cfg.secretNamespace}/repoPass".path}}";
        ssh_command = "ssh -i ${config.sops.secrets."${cfg.secretNamespace}/sshKey".path} -o StrictHostKeyChecking=no";
        verbosity = 1;
        remote_path = "borg14"; # requried for rsync.net
        extra_borg_options = {
          create = "--list --filter=AME";
        };

        # configure notifications via gotify
        commands = [
          {
            after = "error";
            run = [
              "${lib.getExe pkgs.curl} -sSL -H @${config.sops.templates."${cfg.secretNamespace}/gotifyHeaders".path} https://gotify.hanse.de/message -X POST -F \"title=Backup Failed\" -F \"message=${config.networking.fqdnOrHostName} failed to backup its data: {error}\" -F \"priority=8\""
            ];
          }
        ];

        # enable postgres backup if required
        postgresql_databases = lib.mkIf cfg.backupPostgres (
          let
            pgConfig = config.services.postgresql;
          in [
          {
            name = "all";
            format = "directory";
            psql_command = lib.getExe' pgConfig.package "psql";
            pg_dump_command = lib.getExe' pgConfig.package "pg_dump";
            pg_restore_command = lib.getExe' pgConfig.package "pg_restore";
          }
        ]);
      } // cfg.settings;
    };

    # configure sops secrets with backup credentials
    sops.secrets = {
      "${cfg.secretNamespace}/sshKey" = { };
      "${cfg.secretNamespace}/repoPass" = { };
      "${cfg.secretNamespace}/gotifyToken" = { };
    };
    sops.templates = {
      "${cfg.secretNamespace}/gotifyHeaders".content = ''
        Authorization: Bearer ${config.sops.placeholder."${cfg.secretNamespace}/gotifyToken"}
      '';
    };
  };
}

