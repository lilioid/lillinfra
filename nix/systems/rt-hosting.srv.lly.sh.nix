{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
let
  data.network = import ../data/hosting_network.nix { inherit lib; };

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
    ../modules/hosting_guest.nix
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
      "20-vmsBene" = mkTenantNet "vmsBene" data.network.tenants.bene.tenantId ["37.153.156.172"];
      "20-vmsIsabell" = mkTenantNet "vmsIsabell" data.network.tenants.isabell.tenantId ["37.153.156.175"];
      "20-vmsTimon" = mkTenantNet "vmsTimon" data.network.tenants.timon.tenantId ["37.153.156.171"];
    };
  };

  networking.nftables.enable = true;
  networking.nat = {
    enable = true;
    externalInterface = "enp1s0";
    internalIPs = [
      "10.0.10.0/24"
      "10.0.11.0/24"
      "10.0.12.0/24"
      "10.0.13.0/24"
    ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  services.frr = {
    bgpd.enable = true;
    bgpd.extraOptions = [
      "--listenon=2a10:9906:1002:0:125::126"
      "--listenon=::1"
      "--listenon=127.0.0.1"
    ];
    config = ''
      frr version 10.1
      frr defaults traditional

      hostname rt-hosting.srv.ftsell.de

      ! BGP Router config
      router bgp 214493
        no bgp default ipv4-unicast
        bgp default ipv6-unicast
        bgp ebgp-requires-policy
        no bgp network import-check

        neighbor myroot peer-group
        neighbor myroot remote-as 39409
        neighbor myroot capability dynamic
        neighbor 2a10:9906:1002::2 peer-group myroot

        address-family ipv6 unicast
          network 2a10:9902:111::/48
          # redistribute kernel
          # aggregate-address 2a10:9902:111::/48 summary-only
          neighbor myroot prefix-list pl-allowed-export out
          neighbor myroot prefix-list pl-allowed-import in
        exit-address-family

      ip prefix-list pl-allowed-import seq 5 permit ::/0
      ip prefix-list pl-allowed-export seq 5 permit 2a10:9902:111::/48
    '';
  };

  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [
          "vmsLilly"
          "vmsBene"
          "vmsTimon"
          "vmsIsabell"
        ];
      };
      lease-database = {
        name = "/var/lib/kea/dhcp4.leases";
        persist = true;
        type = "memfile";
      };
      rebind-timer = 2000;
      renew-timer = 1000;
      valid-lifetime = 4000;
      authoritative = true;
      option-data = [
        {
          name = "domain-name-servers";
          data = "9.9.9.9";
        }
        {
          name = "routers";
          data = "37.153.156.168";
        }
      ];
      shared-networks = [
        {
          # network for lilly
          name = "lillyNet";
          interface = "vmsLilly";
          subnet4 = [
            {
              id = 1;
              subnet = "37.153.156.169/30";
              pools = [ { pool = "37.153.156.169 - 37.153.156.170"; } ];
              reservations = [
                {
                  # gtw.srv.ftsell.de
                  hw-address = "BC:24:11:94:E3:C3";
                  ip-address = "37.153.156.169";
                }
                {
                  # mail-srv
                  hw-address = "BC:24:11:6D:82:1E";
                  ip-address = "37.153.156.170";
                }
              ];
            }
            {
              id = 2;
              subnet = "10.0.10.0/24";
              pools = [ { pool = "10.0.10.10 - 10.0.10.254"; } ];
              reservations = [
                {
                  # gtw.srv.myroot.intern
                  hw-address = "BC:24:11:DE:56:03";
                  ip-address = "10.0.10.2";
                }
                {
                  # vpn.srv.myroot.intern
                  hw-address = "BC:24:11:6A:70:69";
                  ip-address = "10.0.10.11";
                }
                {
                  # mail.srv.myroot.intern
                  hw-address = "BC:24:11:D0:67:E4";
                  ip-address = "10.0.10.12";
                  option-data = [
                    {
                      "name" = "routers";
                      "data" = "";
                    }
                  ];
                }
                {
                  # nas.srv.myroot.intern
                  hw-address = "BC:24:11:CB:0E:A8";
                  ip-address = "10.0.10.14";
                }
                {
                  # k8s-ctl.srv.myroot.intern
                  hw-address = "BC:24:11:A2:4E:25";
                  ip-address = "10.0.10.15";
                }
                {
                  # k8s-worker1.srv.myroot.intern
                  hw-address = "BC:24:11:EB:C6:02";
                  ip-address = "10.0.10.16";
                }
                {
                  # k8s-worker2.srv.myroot.intern
                  hw-address = "BC:24:11:88:46:E2";
                  ip-address = "10.0.10.17";
                }
              ];
              option-data = [
                {
                  name = "routers";
                  data = "10.0.10.2";
                }
              ];
            }
          ];
        }

        {
          # network for bene
          name = "beneNet";
          interface = "vmsBene";
          subnet4 = [
            {
              id = 3;
              subnet = "37.153.156.172/32";
              pools = [ { pool = "37.153.156.172 - 37.153.156.172"; } ];
              reservations = [
                {
                  # bene-server
                  hw-address = "BC:24:11:F9:84:34";
                  ip-address = "37.153.156.172";
                }
              ];
            }
            {
              id = 4;
              subnet = "10.0.11.0/24";
              pools = [ { pool = "10.0.11.10 - 10.0.11.254"; } ];
            }
          ];
        }
        
        {
          # network for timon
          name = "timonNet";
          interface = "vmsTimon";
          subnet4 = [
            {
              id = 9;
              subnet = "37.153.156.171/32";
              pools = [ { pool = "37.153.156.171 - 37.153.156.171"; } ];
              reservations = [
                {
                  # timon-server
                  hw-address = "BC:24:11:EE:FB:EE";
                  ip-address = "37.153.156.171";
                }
              ];
            }
            {
              id = 10;
              subnet = "10.0.14.0/24";
              pools = [ { pool = "10.0.14.10 - 10.0.14.254"; } ];
            }
          ];
        }

        {
          # network for isabell
          name = "isabellNet";
          interface = "vmsIsabell";
          subnet4 = [
            {
              id = 11;
              subnet = "37.153.156.175/32";
              pools = [ { pool = "37.153.156.175 - 37.153.156.175"; } ];
              reservations = [
                {
                  # isabell-server
                  hw-address = "BC:24:11:0B:C6:6D";
                  ip-address = "37.153.156.175";
                }
              ];
            }
            {
              id = 12;
              subnet = "10.0.15.0/24";
              pools = [ { pool = "10.0.15.10 - 10.0.15.254"; } ];
            }
          ];
        }
      ];
    };
  };

  services.radvd = {
    enable = true;
    config = ''
      interface vmsLilly {
        AdvSendAdvert on;
        prefix 2a10:9902:111:10::/64 {};
      };

      interface vmsBene {
        AdvSendAdvert on;
        prefix 2a10:9902:111:11::/64 {};
      };

      interface vmsTimon {
        AdvSendAdvert on;
        prefix 2a10:9902:111:14::/64 {};
      };

      interface vmsIsabell {
        AdvSendAdvert on;
        prefix 2a10:9902:111:15::/64 {};
      };
    '';
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
