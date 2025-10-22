{ pkgs, lib, config, ... }: {
  custom.preset = "aut-sys-vm";

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "li@lly.sh";

  # enable my standard syncthing integration
  custom.user-syncthing.enable = true;

  # expose the service ports and the WebGUI via a reverse proxy
  services.syncthing.openDefaultPorts = true;
  services.nginx = {
    enable = false;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    clientMaxBodySize = "1g";
    virtualHosts."sync.aut-sys.de" = {
      forceSSL = true;
      enableACME = true;
      locations."/".proxyPass = "http://localhost:8384";
    };
  };

  # run an authentik ldap outpost for centralized password management
  systemd.services."authentik-ldap-outpost" = {
    description = "Authentik LDAP Outpost";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    script = lib.getExe pkgs.authentik-outposts.ldap;
    serviceConfig."EnvironmentFile" = config.sops.templates."authentik-env".path;
  };

  sops = {
    secrets."authentik-outpost-token" = {};
    templates."authentik-env" = {
      restartUnits = [ config.systemd.services."authentik-ldap-outpost".name ];
      content = ''
        AUTHENTIK_HOST=https://auth.aut-sys.de
        AUTHENTIK_TOKEN=${config.sops.placeholder."authentik-outpost-token"}
      '';
    };
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "25.05";
  system.stateVersion = "25.05";
}
