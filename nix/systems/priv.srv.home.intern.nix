{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
let
  vPaperless = "latest";
  vPaperlessRedis = "7";
  vGotenberg = "8.7";
  vTika = "latest";

  vImmich = "v1.117.0";
  vImmichRedis = "6.2-alpine";

  vHomeAssistant = "stable";

  mosquittoConf = pkgs.writeText "mosquitto.conf" ''
    listener 1883 0.0.0.0
    listener 1883 ::
    allow_anonymous true
  '';
in
{
  imports = [
    ../modules/hosting_guest.nix
  ];

  # boot config
  boot.supportedFilesystems.zfs = true;
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/1e6410b4-2756-4153-a210-df9ee4f12be4";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/6A78-AB7F";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  # network config
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks.enp1s0 = {
      matchConfig.Type = "ether";
      networkConfig.DHCP = "yes";
    };
  };

  # general hosting config
  custom.mailRelay.enable = true;
  services.zfs.autoSnapshot.enable = true;
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  networking.firewall.allowedTCPPorts = [
    8000 # paperless web
    8384 # syncthing gui
    3001 # immich server
    8123 # home assistant
    1883 # mqtt server (exposed so that tasmota devices can access it)
  ];

  systemd.targets."encrypted-services" = {
    unitConfig."AssertPathIsMountPoint" = "/srv/data/encrypted";
  };

  # samba server config
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      SyncPictures = {
        path = "/srv/data/encrypted/syncthing/SyncPictures";
        comment = "Camera folder";
        "read only" = true;
        browseable = true;
        "guest ok" = false;
        "force group" = "syncthing";
        "force user" = "syncthing";
      };
      "Paperless Consume" = {
        "path" = "/srv/data/encrypted/paperless/consume";
        "comment" = "Paperless Consume";
        "read only" = false;
        "browseable" = true;
        "guest ok" = false;
        "force group" = "root";
        "force user" = "root";
      };
    };
  };

  # syncthing service
  systemd.services."syncthing".wantedBy = lib.mkForce [ "encrypted-services.target" ];
  services.syncthing = {
    enable = true;
    dataDir = "/srv/data/encrypted/syncthing";
    settings.options.urAccepted = -1;
    guiAddress = "0.0.0.0:8384";
    openDefaultPorts = true;
    overrideFolders = false;
    overrideDevices = false;
  };

  # postgres service
  systemd.services."postgresql".wantedBy = lib.mkForce [ "encrypted-services.target" ];
  services.postgresql = {
    enable = true;
    extensions = ps: with ps; [ pgvector ];
    ensureDatabases = [
      "root"
      "lilly"
      "paperless"
      "immich"
    ];
    ensureUsers = [
      {
        name = "lilly";
        ensureDBOwnership = true;
        ensureClauses.superuser = true;
      }
      {
        name = "root";
        ensureDBOwnership = true;
        ensureClauses.superuser = true;
      }
      {
        name = "paperless";
        ensureDBOwnership = true;
      }
      {
        name = "immich";
        ensureDBOwnership = true;
      }
    ];
  };

  # paperless webserver
  systemd.services."podman-paperless-web".wantedBy = lib.mkForce [ "encrypted-services.target" ];
  virtualisation.oci-containers.containers."paperless-web" = {
    image = "ghcr.io/paperless-ngx/paperless-ngx:${vPaperless}";
    dependsOn = [
      "paperless-broker"
      "paperless-gotenberg"
      "paperless-tika"
    ];
    volumes = [
      "/srv/data/encrypted/paperless/webserver/data:/usr/src/paperless/data"
      "/srv/data/encrypted/paperless/webserver/media:/usr/src/paperless/media"
      "/srv/data/encrypted/paperless/consume:/usr/src/paperless/consume"
      "/srv/data/encrypted/paperless/export:/usr/src/paperless/export"
    ];
    environment = {
      "PAPERLESS_URL" = "https://docs.home.lly.sh";
      "PAPERLESS_TRUSTED_PROXIES" = "192.168.20.102";
      "PAPERLESS_REDIS" = "redis://localhost:6379";
      "PAPERLESS_DBENGINE" = "postgresql";
      "PAPERLESS_DBHOST" = "localhost";
      "PAPERLESS_TIKA_ENABLED" = "1";
      "PAPERLESS_TIKA_GOTENBERG_ENDPOINT" = "http://localhost:3000";
      "PAPERLESS_TIKA_ENDPOINT" = "http://localhost:9998";
    };
    extraOptions = [ "--net=host" ];
  };

  # paperless redis broker
  systemd.services."podman-paperless-broker".wantedBy = lib.mkForce [ "encrypted-services.target" ];
  virtualisation.oci-containers.containers."paperless-broker" = {
    image = "docker.io/library/redis:${vPaperlessRedis}";
    volumes = [
      "/srv/data/encrypted/paperless/redis:/data"
    ];
    extraOptions = [ "--net=host" ];
  };

  # paperless gotenberg
  virtualisation.oci-containers.containers."paperless-gotenberg" = {
    image = "docker.io/gotenberg/gotenberg:${vGotenberg}";
    cmd = [
      "gotenberg"
      "--chromium-disable-javascript=true"
      "--chromium-allow-list=file:///tmp/.*"
    ];
    extraOptions = [ "--net=host" ];
  };

  # paperless tika
  virtualisation.oci-containers.containers."paperless-tika" = {
    image = "docker.io/apache/tika:${vTika}";
    extraOptions = [ "--net=host" ];
  };

  # immich webserver
  systemd.services."podman-immich-server".wantedBy = lib.mkForce [ "encrypted-services.target" ];
  virtualisation.oci-containers.containers."immich-server" = {
    image = "ghcr.io/immich-app/immich-server:${vImmich}";
    dependsOn = [ "immich-redis" ];
    volumes = [
      "/srv/data/encrypted/immich/media:/usr/src/app/upload"
      "/srv/data/encrypted/syncthing/SyncPictures:/usr/src/app/extern/SyncPictures:ro"
      "/etc/localtime:/etc/localtime:ro"
    ];
    environment = {
      TZ = "Europe/Berlin";
      IMMICH_TRUSTED_PROXIES = "192.168.20.102";
      DB_HOSTNAME = "localhost";
      DB_USERNAME = "immich";
      DB_PASSWORD = "immich";
      DB_DATABASE_NAME = "immich";
      DB_VECTOR_EXTENSION = "pgvector";
      REDIS_HOSTNAME = "localhost";
      REDIS_PORT = "6380";
    };
    extraOptions = [
      "--net=host"
      "--group-add=237"
    ];
  };

  # immich machine-learning
  systemd.services."podman-immich-ml".wantedBy = lib.mkForce [ "encrypted-services.target" ];
  virtualisation.oci-containers.containers."immich-ml" = {
    image = "ghcr.io/immich-app/immich-machine-learning:${vImmich}";
    volumes = [
      "/srv/data/encrypted/immich/ml-cache:/cache"
    ];
    environment = config.virtualisation.oci-containers.containers."immich-server".environment;
    extraOptions = [ "--net=host" ];
  };

  # immich redis
  virtualisation.oci-containers.containers."immich-redis" = {
    image = "docker.io/library/redis:${vImmichRedis}";
    cmd = [
      "--port"
      "6380"
    ];
    extraOptions = [ "--net=host" ];
  };

  # home assistant
  systemd.services."podman-home-assistant".wantedBy = lib.mkForce [ "encrypted-services.target" ];
  virtualisation.oci-containers.containers."home-assistant" = {
    image = "ghcr.io/home-assistant/home-assistant:${vHomeAssistant}";
    volumes = [
      "/srv/data/encrypted/homeassistant:/config"
      "/run/dbus:/run/dbus:ro"
    ];
    environment = {
      TZ = "Europe/Berlin";
    };
    extraOptions = [
      "--net=host"
      "--privileged"
      "--device=/dev/ttyUSB0:/dev/ttyUSB0"
    ];
  };

  # home assistant mqtt server
  virtualisation.oci-containers.containers."mosquitto" = {
    image = "docker.io/eclipse-mosquitto";
    volumes = [
      "${mosquittoConf}:/mosquitto/config/mosquitto.conf:ro"
    ];
    extraOptions = [ "--net=host" ];
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "24.05";
  networking.hostId = "1a091689";
}
