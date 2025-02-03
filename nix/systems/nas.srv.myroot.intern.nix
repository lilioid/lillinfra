{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../modules/hosting_guest.nix
    ../modules/vpn_client.nix
  ];

  # filesystem config (including zfs which adds additional mountpoints automatically)
  networking.hostId = "d1c39a07";
  #boot.supportedFilesystems = [ "zfs" ];
  boot.zfs = {
    forceImportRoot = false;
    #extraPools = [ "hdd" "ssd" ];
  };
  boot.loader.grub.device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/1a58acb9-6cd2-4c39-a8e1-edd226eb1e14";
      fsType = "ext4";
    };
  };

  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];

  # networking config
  custom.mailRelay.enable = true;
  networking.useDHCP = false;
  systemd.network.networks."99-default-ether".networkConfig.IPv6AcceptRA = false;

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
      host all all 10.0.10.0/24 md5
      host all all 2a10:9902:111:10::/64 md5
    '';
  };

  # nfs server config
  services.nfs.server = {
    enable = true;
    statdPort = 4000;
    lockdPort = 4001;
    mountdPort = 4002;
    exports = ''
      /srv/ssd/k8s 10.0.10.0/24(rw,mp,no_root_squash,crossmnt)
      /srv/hdd/k8s 10.0.10.0/24(rw,mp,no_root_squash,crossmnt)
    '';
  };

  # open firewall for filesystem access
  networking.nftables.enable = true;
  networking.firewall = {
    allowedTCPPorts = [
      5432 # postgresql
      2049 # nfs
      config.services.nfs.server.statdPort
      config.services.nfs.server.lockdPort
      config.services.nfs.server.mountdPort
    ];
    allowedUDPPorts = [
      2049 # nfs
      51820 # wireguard
      config.services.nfs.server.statdPort
      config.services.nfs.server.lockdPort
      config.services.nfs.server.mountdPort
    ];
  };

  # backup config
  services.zfs.autoSnapshot.enable = true;
  custom.backup.rsync-net = {
    enable = true;
    sourceDirectories = [
      "/root"
      "/home/lilly"
      "/srv/ssd"
      "/srv/hdd"
    ];
    backupPostgres = true;
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "24.05";
}
