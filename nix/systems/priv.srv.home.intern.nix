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

  vUnify = "9.2.87";

  mosquittoConf = pkgs.writeText "mosquitto.conf" ''
    listener 1883 0.0.0.0
    listener 1883 ::
    allow_anonymous true
  '';
in
{
  imports = [
    ../modules/home_vm.nix
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

  # general hosting config
  custom.mailRelay.enable = true;
  services.zfs.autoSnapshot.enable = true;
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # prefer routing via the server net because firewall permissions are granted there
  systemd.network = {
    enable = true;
    networks."20-server-net" = {
      matchConfig.MACAddress = "52:54:00:9f:4c:d9";
      DHCP = "yes";
      networkConfig.IPv6AcceptRA = lib.mkDefault true;
      routes = [
        {
          Gateway = "_dhcp4";
          Metric = 512;
        }
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [
    8000 # paperless web
    8384 # syncthing gui
    3001 # immich server
    8123 # home assistant
    1883 # mqtt server (exposed so that tasmota devices can access it)
    8080 # unifi network application (web interface)
    8443 # unify network application (web interface https)
    6789 # unifi network application (mobile throughput test)
  ];
  networking.firewall.allowedUDPPorts = [
    3478 # unifi network application (STUN)
    1900 # unifi network application (controller discovery)
    5514 # unifi network application (remote syslog)
    10001 # unifi network application (AP Discovery)
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

  # unifi controller
  systemd.services."podman-unifi-network-application" = {
    wantedBy = lib.mkForce [ "encrypted-services.target" ];
    requires = [ "podman-unifi-mongodb.service" ];
    after = [ "podman-unifi-mongodb.service" ];
  };
  virtualisation.oci-containers.containers."unifi-network-application" = {
    image = "lscr.io/linuxserver/unifi-network-application:${vUnify}";
    volumes = [
      "/srv/data/encrypted/unifi-network-application/unifi-data:/config"
    ];
    environment = {
      TZ = "Europe/Berlin";
      MONGO_USER = "unifi";
      MONGO_PASS = "unifi";
      MONGO_HOST = "localhost";
      MONGO_PORT = "27017";
      MONGO_DBNAME = "unifi";
      MONGO_AUTHSOURCE = "admin";
    };
    extraOptions = [
      "--net=host"
    ];
  };

  virtualisation.oci-containers.containers."unifi-mongodb" =
    let
      initScript = pkgs.writeText "init-mongo.sh" ''
        #!/bin/bash
        if which mongosh > /dev/null 2>&1; then
          mongo_init_bin='mongosh'
        else
          mongo_init_bin='mongo'
        fi
        "$mongo_init_bin" <<EOF
        use $MONGO_AUTHSOURCE
        db.auth("$MONGO_INITDB_ROOT_USERNAME", "$MONGO_INITDB_ROOT_PASSWORD")
        db.createUser({
          user: "$MONGO_USER",
          pwd: "$MONGO_PASS",
          roles: [
            { db: "$MONGO_DBNAME", role: "dbOwner" },
            { db: "''${MONGO_DBNAME}_stat", role: "dbOwner" }
          ]
        })
        EOF
      '';
    in
    {
      image = "docker.io/mongo:6.0";
      environment = {
        MONGO_INITDB_ROOT_USERNAME = "root";
        MONGO_INITDB_ROOT_PASSWORD = "root";
        MONGO_USER = "unifi";
        MONGO_PASS = "unifi";
        MONGO_DBNAME = "unifi";
        MONGO_AUTHSOURCE = "admin";
      };
      volumes = [
        "/srv/data/encrypted/unifi-network-application/mongodb:/data/db"
        "${initScript}:/docker-entrypoint-initdb.d/init-mongo.sh:ro"
      ];
      extraOptions = [
        "--net=host"
      ];
    };

  # backup config
  custom.backup.enable = true;

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "24.05";
  networking.hostId = "1a091689";
}
