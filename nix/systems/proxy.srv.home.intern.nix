{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
let
  vhostDefaults = {
    forceSSL = true;
    enableACME = true;
  };
in
{
  imports = [
    ../modules/home_vm.nix
    ../modules/vpn_client.nix
  ];

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

  custom.mailRelay.enable = true;

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
        serverAliases = [ "sync.home.ftsell.de" ];
        locations."/".proxyPass = "http://priv.srv.home.intern:8384";
      };

      "ha.home.lly.sh" = vhostDefaults // {
        serverAliases = [ "ha.home.ftsell.de" ];
        locations."/" = {
          proxyPass = "http://priv.srv.home.intern:8123";
          proxyWebsockets = true;
        };
      };

      "docs.home.lly.sh" = vhostDefaults // {
        serverAliases = [ "docs.home.ftsell.de" ];
        locations."/".proxyPass = "http://priv.srv.home.intern:8000";
      };

      "pics.home.lly.sh" = vhostDefaults // {
        serverAliases = [ "pics.home.lly.sh" ];
        locations."/".proxyPass = "http://priv.srv.home.intern:3001";
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

  # decrypted sops secrets
  sops.secrets."ddclient/desec_token" = { };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "24.05";
  networking.hostId = "1a091689";
}
