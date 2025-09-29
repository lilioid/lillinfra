{ modulesPath, ... }: {
  custom.preset = "aut-sys-lxc";

  # allow connections from local network to postgres
  networking.nftables.enable = true;
  networking.firewall.extraInputRules = ''
      ip saddr { 185.161.130.4 } tcp dport 5432 accept
      ip6 saddr { 2a07:c481:2:5::/64, 2a07:c481:2:6::/64, 2a07:c481:2:7::/64 } tcp dport 5432 accept
    '';

  # postgres config
  systemd.services."postgresql".serviceConfig."Restart" = "on-failure";
  services.postgresql = {
    enable = true;
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
      host all all 185.161.130.0/28 scram-sha-256
    '';
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "24.05";
}
