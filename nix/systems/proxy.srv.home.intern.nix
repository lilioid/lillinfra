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
    ../modules/hosting_guest.nix
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

  # network config
  custom.mailRelay.enable = true;
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks.enp1s0 = {
      matchConfig.Type = "ether";
      networkConfig.DHCP = "yes";
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  networking.firewall.allowedUDPPorts = [
    80
    443
  ];

  # dyndns for home.lly.sh
  services.ddclient = {
    enable = true;
    usev4 = "web, web=https://checkipv4.dedyn.io/";
    server = "update.dedyn.io";
    username = "lly.sh";
    domains = [ "home.lly.sh" ];
    passwordFile = "/run/secrets/ddclient/desec_token";
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
