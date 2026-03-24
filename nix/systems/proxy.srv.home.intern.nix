{
  config,
  ...
}:
let
  vhostDefaults = {
    forceSSL = true;
    enableACME = true;
  };
in
{
  custom.preset = "home-vm";

  # TODO: Reconfigure vpn client

  # boot config
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/db0274b7-1d3a-4839-afcd-a4b662f52b79";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/53AA-C797";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  # network config
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  networking.firewall.allowedUDPPorts = [
    80
    443
    51820
  ];

  # dyndns for home.lly.sh
  sops.secrets."ddclient/desec_token" = { };
  services.ddclient = {
    enable = true;
    verbose = true;
    usev4 = "webv4, webv4=https://checkipv4.dedyn.io/";
    #    usev6 = "webv6, webv6=https://checkipv6.dedyn.io/";
    usev6 = "disabled";
    server = "update.dedyn.io";
    username = "lly.sh";
    domains = [ "home.lly.sh" ];
    passwordFile = config.sops.secrets."ddclient/desec_token".path;
  };

  # web server config
  security.acme = {
    acceptTerms = true;
    defaults.email = "webmaster@lly.sh";
  };

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    clientMaxBodySize = "1g";
    virtualHosts = {

      "sync.home.lly.sh" = vhostDefaults // {
        locations."/".proxyPass = "http://priv.srv.home.intern:8384";
      };

      "ha.home.lly.sh" = vhostDefaults // {
        locations."/" = {
          proxyPass = "http://priv.srv.home.intern:8123";
          proxyWebsockets = true;
        };
      };

      "docs.home.lly.sh" = vhostDefaults // {
        locations."/".proxyPass = "http://priv.srv.home.intern:8000";
      };

      "unifi.home.lly.sh" = vhostDefaults // {
        locations."/" = {
          proxyPass = "https://priv.srv.home.intern:8443";
          extraConfig = ''
            proxy_ssl_verify off; 
          '';
        };
      };
    };
  };

  custom.wg = {
    profiles."autSysVpn" = {
      address = [
        "10.233.228.6/24"
        "2a07:c481:2:4::6/64"
      ];
      peers."autSysRouter" = {
        pubKey = "3Bt7GFzA2PIzhwCWHr8D9+T19H6JMfYoH1ZrRNGMmG8=";
        endpoint = "vpn.aut-sys.de:51820";
        allowedIPs = [
          "10.233.228.0/24" # vpn network
          "2a07:c481:2:4::/64" # vpn network
        ];
      };
    };
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "24.05";
  networking.hostId = "1a091689";
}
