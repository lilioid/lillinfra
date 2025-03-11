{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
let
  data.network = import ../../data/hosting_network.nix { inherit lib; };

  capitalize =
    str:
    lib.concatStrings [
      (lib.strings.toUpper (builtins.substring 0 1 str))
      (builtins.substring 1 (lib.stringLength str) str)
    ];

  renameLink = macAddr: newName: {
    matchConfig = {
      MACAddress = macAddr;
      Type = "ether";
    };
    linkConfig = {
      Name = newName;
    };
  };

  mkTenantNet = netdev: tenantId: routedIp4s: {
    matchConfig.Name = netdev;
    networkConfig = {
      Address = [
        "10.0.${builtins.toString tenantId}.1/24"
        "fe80::1/64"
      ];
      IPv6AcceptRA = false;
    };
    routes =
      (builtins.map (ip4: {
        Destination = ip4;
      }) routedIp4s)
      ++ [
        {
          Destination = "2a10:9902:111:${builtins.toString tenantId}::/64";
        }
      ];
  };

in
{
  imports = [
    ../../modules/hosting_guest.nix
    ./bgp.nix
    ./dhcp.nix
    ./dns.nix
  ];

  # boot config
  boot.loader.grub.device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/228408ee-ca5f-47f9-8612-14f3a2164e82";
      fsType = "ext4";
    };
  };

  environment.systemPackages = with pkgs; [
    traceroute
  ];

  custom.mailRelay.enable = true;
  networking.useDHCP = false;
  systemd.network = {
    enable = true;

    links = {
      "10-myroot" = renameLink data.network.guests.rt-hosting.macAddress "ethMyroot";
      "10-vmsLilly" = renameLink "bc:24:11:e3:12:55" "vmsLilly";
      "10-vmsBene" = renameLink "BC:24:11:51:A0:26" "vmsBene";
      "10-vmsIsabell" = renameLink "BC:24:11:78:50:EF" "vmsIsabell";
      "10-vmsTimon" = renameLink "BC:24:11:9B:CD:5D" "vmsTimon";
      "10-vmsNoah" = renameLink "BC:24:11:9C:BA:D6" "vmsNoah";
      "10-vmsFux" = renameLink "BC:24:11:E3:F0:CC" "vmsFux";
    };

    networks = {
      # upstream interface
      "10-ethMyRoot" = {
        matchConfig.Name = "ethMyroot";
        networkConfig = {
          IPv4ProxyARP = true;
        };
        address = [
          "${data.network.guests.rt-hosting.ipv4}/32"
          "2a10:9906:1002:0:125::126/64"
        ];
        gateway = [
          "37.153.156.1"
        ];
        routes = [
          {
            # default gateway can always be reached directly
            Destination = "37.153.156.1";
          }
        ];
      };

      # downstream client interfaces
      "20-vmsLilly" = mkTenantNet "vmsLilly" data.network.tenants.lilly.tenantId [
        "37.153.156.169"
        "37.153.156.170"
      ];
      "20-vmsBene" = mkTenantNet "vmsBene" data.network.tenants.bene.tenantId [ "37.153.156.172" ];
      "20-vmsIsabell" = mkTenantNet "vmsIsabell" data.network.tenants.isabell.tenantId [
        "37.153.156.175"
      ];
      "20-vmsTimon" = mkTenantNet "vmsTimon" data.network.tenants.timon.tenantId [ "37.153.156.171" ];
      "20-vmsNoah" = mkTenantNet "vmsNoah" data.network.tenants.noah.tenantId [ "37.153.156.173" ];
      "20-vmsFux" = mkTenantNet "vmsFux" data.network.tenants.fux.tenantId [ "37.153.156.176" ];
    };
  };

  networking.nftables.enable = true;
  networking.nat = {
    enable = true;
    externalInterface = "enp1s0";
    internalIPs = [
      "10.0.10.0/24"
    ];
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = "1";
    "net.ipv6.conf.all.forwarding" = "1";
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "24.05";
}
