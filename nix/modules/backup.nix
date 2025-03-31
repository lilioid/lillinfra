{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.custom.backup;
in
{
  imports = [ ];

  options = {
    custom.backup.rsync-net = {
      enable = mkEnableOption "backups to rsync.net";
      passwordFilePath = mkOption {
        type = types.str;
        description = "The path inside the hosts secret data file which contains the encryption passphrase of the borg archive";
        default = "backup/rsync-net/encryption-passphrase";
      };
      sshKeyPath = mkOption {
        type = types.str;
        description = "The path inside the hosts secret data file which holds the ssh private key that is used to connect to rsync.net";
        default = "backup/rsync-net/ssh-key";
      };
      sshUser = mkOption {
        type = types.str;
        default = "zh4525";
      };
      sshHost = mkOption {
        type = types.str;
        default = "zh4525.rsync.net";
      };
      repoPath = mkOption {
        description = "The path on rsync.net which holds the borg repository to which this host is backed up";
        type = types.str;
        defaultText = "./backups/{config.networking.fqdnOrHostName}";
        default = "./backups/${config.networking.fqdnOrHostName}";
      };
      sourceDirectories = mkOption {
        type = types.listOf types.str;
        default = [
          "/home/lilly"
          "/root"
        ];
      };
      backupPostgres = mkOption {
        type = types.bool;
        default = false;
      };
      hooks = {
        beforeBackup = mkOption {
          type = types.listOf types.str;
          default = [ ];
        };
        afterBackup = mkOption {
          type = types.listOf types.str;
          default = [ ];
        };
      };
    };
  };

  config = mkIf cfg.rsync-net.enable {
    services.borgmatic.enable = true;
    services.borgmatic.configurations."rsync-net" = {
      source_directories = cfg.rsync-net.sourceDirectories;
      repositories = [
        {
          label = "rsync.net";
          path = "ssh://${cfg.rsync-net.sshUser}@${cfg.rsync-net.sshHost}/${cfg.rsync-net.repoPath}";
        }
      ];
      one_file_system = true;
      exclude_patterns = [
        "/home/*/.rustup/toolchains"
        "/home/*/.vim/undodir"
        "/home/*/.local/share/containers"
        "/home/*/.local/share/virtualenvs"
        "/home/*/.local/share/JetBrains/Toolbox/apps/"
        "/home/*/.local/share/Steam/"
        "/home/*/Downloads"
        "/home/*/Games"
        "/home/*/.cache"
        "/home/*/.local/share/Trash"
        "/home/*/.local/share/pnpm/store"
        "/home/*/.npm"
        "/home/*/Projects/**/target/"
        "/root/.cache"
        "**/node_modules/"
        "**/cache/"
        "**/Cache/"
        "**/*.cache"
      ];
      encryption_passcommand = "${pkgs.coreutils}/bin/cat /run/secrets/${cfg.rsync-net.passwordFilePath}";
      archive_name_format = "{hostname}--{now}";
      relocated_repo_access_is_ok = true;
      keep_hourly = 48;
      keep_daily = 7;
      keep_weekly = 8;
      ssh_command = "ssh -i /run/secrets/${cfg.rsync-net.sshKeyPath} -o StrictHostKeyChecking=no";
      extra_borg_options.create = "--list --filter=AME";
      exclude_if_present = [ ".nobackup" ];
      postgresql_databases = lib.mkIf cfg.rsync-net.backupPostgres [
        {
          name = "all";
          format = "directory";
          psql_command = with pkgs; "${postgresql}/bin/psql";
          pg_dump_command = with pkgs; "${postgresql}/bin/pg_dump";
        }
      ];
      before_backup = cfg.rsync-net.hooks.beforeBackup;
      after_backup = cfg.rsync-net.hooks.afterBackup;
    };

    # create overwrites for the systemd unit to make it work in my system
    systemd.services."borgmatic" = {
      serviceConfig = {
        #LockPersonality = false;
        PrivateDevices = false;
        #ProtectKernelTunables = false;
      };
    };

    systemd.timers.borgmatic.timerConfig.OnCalendar = "hourly";

    sops.secrets = {
      ${cfg.rsync-net.sshKeyPath} = {
        mode = "0400";
      };
      ${cfg.rsync-net.passwordFilePath} = {
        mode = "0400";
      };
    };
  };
}
