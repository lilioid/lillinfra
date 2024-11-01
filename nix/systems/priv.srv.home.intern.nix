{ modulesPath, config, lib, pkgs, home-manager, ... }: {
  imports = [
    ../modules/base_system.nix
    ../modules/hosting_guest.nix
    ../modules/user_ftsell.nix
  ];

  # boot config
  boot.supportedFilesystems.zfs = true;
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/1e6410b4-2756-4153-a210-df9ee4f12be4";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/6A78-AB7F";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  };

  # network config
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks.enp1s0 = {
      matchConfig.Type = "ether";
      networkConfig.DHCP = "yes";
    };
  };

  # general hosting config
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  networking.firewall.allowedTCPPorts = [
    8384 # syncthing gui
  ];

  # syncthing service
  services.syncthing = {
    enable = true;
    dataDir = "/srv/data/encrypted/syncthing";
    settings.options.urAccepted = -1;
    guiAddress = "0.0.0.0:8384";
    openDefaultPorts = true;
    overrideFolders = false;
    overrideDevices = false;
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.ftsell.home.stateVersion = "24.05";
  system.stateVersion = "24.05";
  networking.hostId = "1a091689";
}
