{ modulesPath, ... }: {
  imports = [
    "${modulesPath}/virtualisation/proxmox-lxc.nix"
  ];

  custom.preset = "aut-sys-lxc";

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
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "24.05";
}
