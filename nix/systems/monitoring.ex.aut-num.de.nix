{
  config,
  pkgs,
  lib,
  ...
}:
{
  # boot config
  boot.initrd.systemd.enable = true;
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # configure systemd-boot bootloader
  boot.loader.systemd-boot = {
    enable = true;
    editor = false;
    configurationLimit = 4;
  };

  # partitioning and filesystems
  disko.devices = {
    disk = {
      system = {
        type = "disk";
        device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              type = "ef00";
              start = "1M";
              size = "500M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            swap = {
              size = "4G";
              content = {
                type = "swap";
                discardPolicy = "both";
              };
            };
            root = {
              type = "8300";
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [
                  "defaults"
                  "noatime"
                ];
              };
            };
          };
        };
      };
    };
  };

  # network config
  # disable privacy extensions (because servers get cofused with multiple addresses sometimes)
  # also enable managed configuration through my router
  networking.useDHCP = false;
  networking.nameservers = [ "2620:fe::fe" "9.9.9.9" ];
  systemd.network = {
    enable = true;
    config.networkConfig."IPv6PrivacyExtensions" = false;
    networks."eth0" = {
      matchConfig.Type = "ether";
      matchConfig.Kind = "!bond bridge gre tun veth";
      address = [ "212.12.50.243/27" ];
      gateway = [ "212.12.50.225" ];
      networkConfig.DHCP = "no";
      networkConfig.IPv6AcceptRA = "no";
    };
  };

  # general os config
  security.sudo.wheelNeedsPassword = false;
  services.qemuGuest.enable = true;
  documentation.nixos.enable = false;

  # ssh server
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      AllowGroups = lib.mkDefault [ "users" ];
    };
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "26.05";
  system.stateVersion = "26.05";
}
