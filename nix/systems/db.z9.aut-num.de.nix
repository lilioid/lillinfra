{ pkgs, lib, config, ... }:
let
  pgUpgradeScript = oldPostgres: newPostgres: pkgs.writeScriptBin "upgrade-pg-cluster" ''
    set -eux
    systemctl stop postgresql

    export NEWDATA="/var/lib/postgresql/${newPostgres.psqlSchema}"
    export NEWBIN="${newPostgres}/bin"

    export OLDDATA="/var/lib/postgresql/${oldPostgres.psqlSchema}"
    export OLDBIN="${oldPostgres}/bin"

    install -d -m 0700 -o postgres -g postgres "$NEWDATA"
    cd "$NEWDATA"
    sudo -u postgres "$NEWBIN/initdb" -D "$NEWDATA" ${lib.escapeShellArgs config.services.postgresql.initdbArgs}

    sudo -u postgres "$NEWBIN/pg_upgrade" \
      --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
      --old-bindir "$OLDBIN" --new-bindir "$NEWBIN" \
      "$@"
  '';
in
{
  custom.preset = "aut-sys-lxc";

  # allow connections from local network to postgres
  networking.firewall.extraInputRules = ''
    ip saddr { 185.161.130.0/28 } tcp dport 5432 accept
    ip6 saddr { 2a07:c481:2:5::/64, 2a07:c481:2:6::/64, 2a07:c481:2:7::/64, 2a07:c481:2:100::/56 } tcp dport 5432 accept
  '';

  environment.systemPackages = with pkgs; [
    #(pgUpgradeScript config.services.postgresql.package postgresql_17)
  ];

  # postgres config
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    extensions = ps: with ps; [ pgvector vectorchord ];
    settings.shared_preload_libraries = [ "vchord" ];
    enableTCPIP = true;
    ensureDatabases = [
      "lilly"
      "root"
    ];
    ensureUsers = [
      {
        name = "lilly";
        ensureDBOwnership = true;
        ensureClauses.superuser = true;
      }
      {
        name = "root";
        ensureDBOwnership = true;
        ensureClauses.superuser = true;
      }
    ];
    authentication = ''
      host all all 2a07:c481:2:5::/64 scram-sha-256
      host all all 2a07:c481:2:6::/64 scram-sha-256
      host all all 2a07:c481:2:7::/64 scram-sha-256
      host all all 2a07:c481:2:100::/56 scram-sha-256
      host all all 185.161.130.0/28 scram-sha-256
    '';
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "24.05";
}
