{ lib }:
let
  mkExposed = macAddress: ipv4: {
    _type = "exposedGuest";
    ipv4 = ipv4;
    macAddress = macAddress;
  };
  mkRouted = macAddress: ipv4: {
    _type = "routedGuest";
    ipv4 = ipv4;
    macAddress = macAddress;
  };
  mkNat = macAddress: ipv4: portForwards: {
    _type = "natGuest";
    ipv4 = ipv4;
    macAddress = macAddress;
    portForwards = portForwards;
  };

  mkTenant = tenantId: {
    _type = "tenant";
    inherit tenantId;
  };

  mkDhcp4Lease = tenant: hostname: macAddr: ipAddr: {
    _type = "dhcp4Lease";
    inherit
      tenant
      hostname
      macAddr
      ipAddr
      ;
  };
in
rec {
  # hosting.srv.ftsell.de server
  #   - Main IPv4:       37.153.156.125
  #   - IPv4 Gateway:    37.153.156.1
  #   - Main IPv6:       2a10:9906:1002:0:125::125/64
  #   - Routed IPv6:     2a10:9906:1002:125::/64
  #   - IPv6 Gateway:    2a10:9906:1002::1
  # additional IPs ordered from MyRoot
  #   - 37.153.156.168 - 37.153.156.175
  # private subnet
  #    - 10.0.0.0/24

  rt-hosting.ip4 = "37.153.156.168";
  rt-hosting.ip6 = "";

  # contains the IP address range from 37.153.156.168 to 37.153.156.179
  # https://netbox.ftsell.de/ipam/ip-ranges/1/
  guestIPs = builtins.map (i: "37.153.156.${builtins.toString i}") (lib.range 169 179);

  # https://netbox.ftsell.de/tenancy/tenants/?group_id=1
  tenants = {
    lilly = mkTenant 10;
    bene = mkTenant 11;
    polygon = mkTenant 12;
    vieta = mkTenant 13;
    timon = mkTenant 14;
    isabell = mkTenant 15;
    noah = mkTenant 16;
  };

  guests = {
    # exposed guests
    rt-hosting = mkExposed "BC:24:11:47:54:53" "37.153.156.168";
    # routed guests
    main-srv = mkRouted "52:54:00:ba:63:25" "37.153.156.169";
    mail-srv = mkRouted "BC:24:11:6D:82:1E" "37.153.156.170";
    bene-server = mkRouted "52:54:00:13:f8:f9" "37.153.156.172";
    polygon-server = mkRouted "52:54:00:f9:64:31" "37.153.156.174";
    timon-server = mkRouted "52:54:00:00:c9:09" "37.153.156.171";
    isabell-srv = mkRouted "52:54:00:2d:2a:26" "37.153.156.175";
    noah-server = mkRouted "BC:24:11:E9:08:F7" "37.153.156.173";
    # nat guests
    vpn-srv = mkNat "52:54:00:8e:97:05" "10.0.0.101" [
      {
        proto = "udp";
        src = 51820;
        dst = 51820;
      }
    ];
  };

  routedGuests = (builtins.filter (i: i._type == "routedGuest") (builtins.attrValues guests));
  natGuests = (builtins.filter (i: i._type == "natGuest") (builtins.attrValues guests));
}
