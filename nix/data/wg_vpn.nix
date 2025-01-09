#
# Definition of the networking topology of my WireGuard-VPN
#
# This module exposes an AttrSet keyed by a clients hostname
#

let
  mkRegistrationAdv = endpoint: allowedIPs: pubKey: keepalive: {
    _type = "vpnClientRegistration";
    inherit
      endpoint
      allowedIPs
      pubKey
      keepalive
      ;
  };
  mkRegistration =
    ipSuffix: pubKey:
    (mkRegistrationAdv null [
      "10.20.30.${builtins.toString ipSuffix}/32"
      "fc10:20:30::${builtins.toString ipSuffix}/128"
    ] pubKey false);

  mkServer = endpoint: allowedIPs: pubKey: keepalive: {
    _type = "vpnServerRegistration";
    inherit endpoint allowedIPs pubKey;
  };
  reg2server =
    clientConf: (mkServer clientConf.endpoint clientConf.allowedIPs clientConf.pubKey false);
in
rec {
  # clients that are known to the VPN server
  knownClients = {
    "nas.srv.myroot.intern" = mkRegistrationAdv "10.0.10.14:51820" [
      "10.20.30.2/32"
      "fc10:20:30::2/128"
    ] "NASFYFuG6XOw+S/0Bu5prkrGrT8t86fJcZdpIEBjynU=" false;
    "proxy.srv.home.intern" = mkRegistrationAdv "home.lly.sh:51820" [
      "10.20.30.3/32"
      "fc10:20:30::3/128"
    ] "GTWotNqG3way+5NacVVs9bDwbLXplo/afSwZzU2XzkU=" false;
    "nas-ole" = mkRegistrationAdv null [
      "10.20.30.105/32"
      "fc10:20:30::105/128"
    ] "NASuIV3T8lYoE2VTnuu+GPqq8Pzh/NHTfL06puPZDTE=" true;
    "lillysPhone" = mkRegistration 102 "PHN5Srlsv3x7+ehWF4SPz0eezcYlm7c0pIU5jXYuYG4=";
    "lillysLaptop" = mkRegistration 103 "LAPcOludjQrjfza0M+XA+fuwxpVfmqRKjBawAxWDyDY=";
    "finnsWorkstation" = mkRegistration 104 "WOrk7yTwmWilfWrOhF2EpmMvK/fC8L3IfGaOnZQnRyA=";
  };

  knownServers = {
    "vpn-server" = mkServer "vpn.lly.sh:51820" [
      "10.20.30.0/24"
      "fc10:20:30::0/64"
    ] "SRVfDEjWZCEcxynQoK1iibpzVeDN61ghTEQPps3pmSY=" false;
    "proxy.srv.home.intern" = reg2server knownClients."proxy.srv.home.intern";
  };

  network = {
    dns = [
      "10.20.30.1"
      "fc10:20:30::1"
    ];
    searchDomain = "vpn.intern.";
  };

  peers = { };
}
