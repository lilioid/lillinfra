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
    custom.backup = {
      enable = mkEnableOption "automatic backup creation";
      sourceDirectories = mkOption {
        type = types.listOf types.str;
        description = "A list of directories from this host that should be backed up";
        default = [
          "/home"
          "/root"
          "/srv"
        ];
      };
      backupPostgres = mkOption {
        default = config.services.postgresql.enable;
        defaultText = "services.postgresql.enable";
        description = "Whether to enable automatic backups of postgresql databases";
        type = types.bool;
      };
      destinations = {
        rsync-net = {
          enable = mkOption {
            default = true;
            description = "Whether to enable backups to rsync.net";
            type = types.bool;
          };
          passwordFilePath = mkOption {
            type = types.str;
            description = "Path to a file which contains the repositories password";
            default = "backup/rsync-net/password";
          };
          sshKeyPath = mkOption {
            type = types.str;
            description = "Path to an SSH private key file that can be used to login to rsync.net";
            default = "backup/rsync-net/ssh-key";
          };
          sshUser = mkOption {
            type = types.str;
            description = "Username for logging into rsync.net";
            default = "zh4525";
          };
          sshHost = mkOption {
            type = types.str;
            description = "Hostname to use when connecting to rsync.net";
            default = "zh4525.rsync.net";
          };
          repoPath = mkOption {
            description = "The path on rsync.net which holds the repository to which this host is backed up";
            type = types.str;
            default = "backups/restic-repo";
          };
        };
      };
    };
  };

  # TODO: Enable postgres backups
  config = mkIf cfg.enable {
    services.restic.backups = {
      "rsync.net" = mkIf cfg.destinations.rsync-net.enable {
        repository = "sftp:${cfg.destinations.rsync-net.sshUser}@${cfg.destinations.rsync-net.sshHost}:${cfg.destinations.rsync-net.repoPath}";
        extraOptions = [
          "sftp.command='ssh ${cfg.destinations.rsync-net.sshUser}@${cfg.destinations.rsync-net.sshHost} -i ${
            config.sops.secrets.${cfg.destinations.rsync-net.sshKeyPath}.path
          } -s sftp'"
        ];
        initialize = true;
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = false;
        };
        pruneOpts = [
          "--keep-hourly=3"
          "--keep-daily=7"
          "--keep-weekly=4"
          "--keep-monthly=6"
        ];
        paths = cfg.sourceDirectories;
        passwordFile = config.sops.secrets.${cfg.destinations.rsync-net.passwordFilePath}.path;
        inhibitsSleep = true;
        extraBackupArgs = [ "--exclude-caches" ];
        exclude = [
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
      };
    };

    # TODO: Build postgres backup

    # configure sops secrets with backup credentials
    sops.secrets = {
      ${cfg.destinations.rsync-net.sshKeyPath} = {
        mode = "0400";
        sopsFile = ../data/shared-secrets/backup.yml;
      };
      ${cfg.destinations.rsync-net.passwordFilePath} = {
        mode = "0400";
        sopsFile = ../data/shared-secrets/backup.yml;
      };
    };
  };
}
