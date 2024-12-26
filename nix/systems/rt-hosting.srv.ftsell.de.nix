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

  mkVlanNetdev = name: vlan: {
    netdevConfig = {
      Name = name;
      Kind = "vlan";
    };
    vlanConfig = {
      Id = vlan;
    };
  };

  mkVlanNetwork = name: vlan: routedIp4s: {
    matchConfig = {
      Name = name;
      Kind = "vlan";
    };
    networkConfig = {
      Address = [
        "10.0.${builtins.toString vlan}.1/24"
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
          Destination = "2a10:9902:111:${builtins.toString vlan}::/64";
        }
      ];
  };

in
{
  imports = [
    ../modules/hosting_guest.nix
    ../modules/base_system.nix
    ../modules/user_ftsell.nix
  ];

  # boot config
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-uuid/83DB-8B4E";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
    "/" = {
      device = "/dev/disk/by-uuid/ac4a51da-dea7-4c32-b949-073dd9fbc592";
      fsType = "ext4";
    };
  };

  environment.systemPackages = with pkgs; [
    traceroute
  ];

  networking.useDHCP = false;
  systemd.network = {
    enable = true;

    netdevs =
      lib.mergeAttrs
        # statically defined netdevs
        { }
        # netdevs derived from hosting_network.nix
        (
          lib.attrsets.concatMapAttrs (name: data: {
            "vlan${capitalize name}" = mkVlanNetdev "vlan${capitalize name}" data.tenantId;
          }) data.network.tenants
        );

    networks.ethMyRoot = {
      matchConfig = {
        Type = "ether";
        MACAddress = "52:54:00:af:bc:45";
      };
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
          routeConfig = {
            Destination = "37.153.156.1";
          };
        }
      ];
    };

    networks.ethVMs = {
      matchConfig = {
        Type = "ether";
        MACAddress = "52:54:00:85:6c:df";
      };
      linkConfig = {
        RequiredForOnline = false;
      };
      networkConfig = {
        LinkLocalAddressing = false;
        VLAN = [
          "vlanLilly"
          "vlanBene"
          "vlanPolygon"
          "vlanVieta"
          "vlanTimon"
          "vlanIsabell"
        ];
      };
    };

    networks."vlanLilly" = mkVlanNetwork "vlanLilly" 10 [
      "37.153.156.169"
      "37.153.156.170"
    ];
    networks."vlanBene" = mkVlanNetwork "vlanBene" 11 [ "37.153.156.172" ];
    networks."vlanPolygon" = mkVlanNetwork "vlanPolygon" 12 [ "37.153.156.174" ];
    networks."vlanVieta" = mkVlanNetwork "vlanVieta" 13 [ "37.153.156.173" ];
    networks."vlanTimon" = mkVlanNetwork "vlanTimon" 14 [ "37.153.156.171" ];
    networks."vlanIsabell" = mkVlanNetwork "vlanIsabell" 15 [ "37.153.156.175" ];
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
          "vlanLilly"
          "vlanBene"
          "vlanPolygon"
          "vlanVieta"
          "vlanTimon"
          "vlanIsabell"
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
          # network for finn
          name = "finnNet";
          interface = "vlanLilly";
          subnet4 = [
            {
              id = 1;
              subnet = "37.153.156.169/30";
              pools = [ { pool = "37.153.156.169 - 37.153.156.170"; } ];
              reservations = [
                {
                  # gtw.srv.ftsell.de
                  hw-address = "52:54:00:43:ff:c6";
                  ip-address = "37.153.156.169";
                }
                {
                  # mail-srv
                  hw-address = "52:54:00:66:e2:38";
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
                  hw-address = "52:54:00:8c:88:66";
                  ip-address = "10.0.10.2";
                }
                {
                  # vpn.srv.myroot.intern
                  hw-address = "52:54:00:8e:97:05";
                  ip-address = "10.0.10.11";
                }
                {
                  # mail.srv.myroot.intern
                  hw-address = "52:54:00:7d:ff:7f";
                  ip-address = "10.0.10.12";
                }
                {
                  # monitoring.srv.myroot.intern
                  hw-address = "52:54:00:00:47:69";
                  ip-address = "10.0.10.13";
                }
                {
                  # nas.srv.myroot.intern
                  hw-address = "52:54:00:2e:74:29";
                  ip-address = "10.0.10.14";
                }
                {
                  # k8s-ctl.srv.myroot.intern
                  hw-address = "52:54:00:58:93:1a";
                  ip-address = "10.0.10.15";
                }
                {
                  # k8s-worker1.srv.myroot.intern
                  hw-address = "52:54:00:e6:1f:51";
                  ip-address = "10.0.10.16";
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
          interface = "vlanBene";
          subnet4 = [
            {
              id = 3;
              subnet = "37.153.156.172/32";
              pools = [ { pool = "37.153.156.172 - 37.153.156.172"; } ];
              reservations = [
                {
                  # bene-server
                  hw-address = "52:54:00:13:f8:f9";
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
          # network for polygon
          name = "polygonNet";
          interface = "vlanPolygon";
          subnet4 = [
            {
              id = 5;
              subnet = "37.153.156.174/32";
              pools = [ { pool = "37.153.156.174 - 37.153.156.174"; } ];
              reservations = [
                {
                  # polygon-server
                  hw-address = "52:54:00:f9:64:31";
                  ip-address = "37.153.156.174";
                }
              ];
            }
            {
              id = 6;
              subnet = "10.0.12.0/24";
              pools = [ { pool = "10.0.12.10 - 10.0.12.254"; } ];
            }
          ];
        }

        {
          # network for vieta
          name = "vietaNet";
          interface = "vlanVieta";
          subnet4 = [
            {
              id = 7;
              subnet = "37.153.156.173/32";
              pools = [ { pool = "37.153.156.173 - 37.153.156.173"; } ];
              reservations = [
                {
                  # polygon-server
                  hw-address = "52:54:00:6d:0e:83";
                  ip-address = "37.153.156.173";
                }
              ];
            }
            {
              id = 8;
              subnet = "10.0.13.0/24";
              pools = [ { pool = "10.0.13.10 - 10.0.13.254"; } ];
            }
          ];
        }

        {
          # network for timon
          name = "timonNet";
          interface = "vlanTimon";
          subnet4 = [
            {
              id = 9;
              subnet = "37.153.156.171/32";
              pools = [ { pool = "37.153.156.171 - 37.153.156.171"; } ];
              reservations = [
                {
                  # timon-server
                  hw-address = "52:54:00:00:c9:09";
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
          interface = "vlanIsabell";
          subnet4 = [
            {
              id = 11;
              subnet = "37.153.156.175/32";
              pools = [ { pool = "37.153.156.175 - 37.153.156.175"; } ];
              reservations = [
                {
                  # isabell-server
                  hw-address = "52:54:00:2d:2a:26";
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
      interface vlanLilly {
        AdvSendAdvert on;
        prefix 2a10:9902:111:10::/64 {};
      };

      interface vlanBene {
        AdvSendAdvert on;
        prefix 2a10:9902:111:11::/64 {};
      };

      interface vlanPolygon {
        AdvSendAdvert on;
        prefix 2a10:9902:111:12::/64 {};
      };

      interface vlanVieta {
        AdvSendAdvert on;
        prefix 2a10:9902:111:13::/64 {};
      };

      interface vlanTimon {
        AdvSendAdvert on;
        prefix 2a10:9902:111:14::/64 {};
      };
    '';
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = "1";
    "net.ipv6.conf.all.forwarding" = "1";
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.ftsell.home.stateVersion = "24.05";
  system.stateVersion = "24.05";
}
