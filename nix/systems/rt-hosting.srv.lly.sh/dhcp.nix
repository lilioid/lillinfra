{ ... }:
{

  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [
          "vmsLilly"
          "vmsBene"
          "vmsTimon"
          "vmsIsabell"
          "vmsFux"
          "vmsNoah"
          "vmsFreddy"
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
          ];
        }

        {
          # network for noah
          name = "noahNet";
          interface = "vmsNoah";
          subnet4 = [
            {
              id = 13;
              subnet = "37.153.156.173/32";
              pools = [ { pool = "37.153.156.173 - 37.153.156.173"; } ];
              reservations = [
                {
                  # noah-server
                  hw-address = "BC:24:11:E9:08:F7";
                  ip-address = "37.153.156.173";
                }
              ];
            }
          ];
        }

        {
          # network for fux
          name = "fuxNet";
          interface = "vmsFux";
          subnet4 = [
            {
              id = 15;
              subnet = "37.153.156.176/32";
              pools = [ { pool = "37.153.156.176 - 37.153.156.176"; } ];
              reservations = [
                {
                  # fux-monitoring
                  hw-address = "BC:24:11:4C:2D:8C";
                  ip-address = "37.153.156.176";
                }
              ];
            }
          ];
        }

        {
          # network for freddy
          name = "freddyNet";
          interface = "vmsFreddy";
          subnet4 = [
            {
              id = 18;
              subnet = "37.153.156.177/32";
              pools = [ { pool = "37.153.156.177 - 37.153.156.177"; } ];
              reservations = [
                {
                  # fux-monitoring
                  hw-address = "BC:24:11:71:42:EE";
                  ip-address = "37.153.156.177";
                }
              ];
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

      interface vmsNoah {
        AdvSendAdvert on;
        prefix 2a10:9902:111:16::/64 {};
      };

      interface vmsFux {
        AdvSendAdvert on;
        prefix 2a10:9902:111:17::/64 {};
      };
      
      interface vmsFreddy {
        AdvSendAdvert on;
        prefix 2a10:9902:111:18::/64 {};
      };
    '';
  };

}
