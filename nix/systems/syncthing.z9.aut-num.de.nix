{ pkgs, lib, config, ... }: {
  custom.preset = "aut-sys-vm";

  # mount shared kubernetes filesystem
  environment.systemPackages = with pkgs; [ ceph-client ];
  environment.etc."ceph/ceph.conf".text = ''
    [global]
          fsid = 13342310-b28f-4d7b-a893-af2984583a92
          mon_host = [v2:[2a07:c481:2:2::101]:3300/0,v1:[2a07:c481:2:2::101]:6789/0] [v2:[2a07:c481:2:2::102]:3300/0,v1:[2a07:c481:2:2::102]:6789/0] [v2:[2a07:c481:2:2::103]:3300/0,v1:[2a07:c481:2:2::103]:6789/0]
          keyfile=${config.sops.secrets."aut-sys-ceph/syncthing/secret".path}
  '';
  fileSystems."ceph-syncthing" = {
    # mount from ceph with user "syncthing", cephfs named "data", and subvolume "syncthing"
    device = "syncthing@.data=/volumes/_nogroup/syncthing/a47016f1-bab1-4f54-a70b-dfe0d356354a";
    mountPoint = "/srv/ceph-syncthing";
    fsType = "ceph";
    options = [
      "rw"
      "noatime"
      "acl"
      "crush_location=host:pve1"
      "read_from_replica=localize"
    ];
    neededForBoot = false;
    noCheck = true;
  };
  fileSystems."photoprism-originals" = {
    # mount photoprism PersistentVolumeClaim in syncthing so that I can sync photos directly into it
    device = "syncthing@.data=/volumes/_nogroup/k8s/83fef1ef-824c-4815-b1f4-477a50b72376/pvc-34a22a90-bf9c-4b29-9891-9b18595d4e3b_photoprism_photoprism-originals";
    mountPoint = "/srv/photoprism-originals";
    fsType = "ceph";
    options = [
      "rw"
      "noatime"
      "acl"
      "crush_location=host:pve1"
      "read_from_replica=localize"
    ];
    neededForBoot = false;
    noCheck = true;
  };

  # enable syncthing
  systemd.services."syncthing" = {
    requires = [ "srv-ceph\\x2dsyncthing.mount" ];
    after = [ "srv-ceph\\x2dsyncthing.mount" ];
  };
  services.syncthing = {
    enable = true;
    group = "users";
    user = "lilly";
    dataDir = "/srv/ceph-syncthing/data";
    configDir = "/srv/ceph-syncthing/config";
    settings.options.urAccepted = -1;
    openDefaultPorts = true;
    overrideFolders = false;
    overrideDevices = false;
  };

  # expose the service ports and the WebGUI via a reverse proxy
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "li@lly.sh";
  services.nginx = {
    enable = true;
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
    secrets."aut-sys-ceph/syncthing/secret" = { };
    secrets."authentik-outpost-token" = { };
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
