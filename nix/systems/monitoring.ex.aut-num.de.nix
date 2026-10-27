{
  config,
  pkgs,
  lib,
  ...
}:
{
  # boot config
  boot.initrd.systemd.enable = true;
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  users.mutableUsers = false;

  # configure systemd-boot bootloader
  boot.loader.systemd-boot = {
    enable = true;
    editor = false;
    configurationLimit = 4;
  };

  # partitioning and filesystems
  disko.devices = {
    disk = {
      system = {
        type = "disk";
        device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              type = "ef00";
              start = "1M";
              size = "500M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            swap = {
              size = "4G";
              content = {
                type = "swap";
                discardPolicy = "both";
              };
            };
            root = {
              type = "8300";
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [
                  "defaults"
                  "noatime"
                ];
              };
            };
          };
        };
      };
    };
  };

  # network config
  # disable privacy extensions (because servers get cofused with multiple addresses sometimes)
  # also enable managed configuration through my router
  networking.useDHCP = false;
  networking.nameservers = [
    "2620:fe::fe"
    "9.9.9.9"
  ];
  systemd.network = {
    enable = true;
    config.networkConfig."IPv6PrivacyExtensions" = false;
    networks."eth0" = {
      matchConfig.Type = "ether";
      matchConfig.Kind = "!bond bridge gre tun veth";
      address = [ "212.12.50.243/27" ];
      gateway = [ "212.12.50.225" ];
      networkConfig.DHCP = "no";
      networkConfig.IPv6AcceptRA = "no";
    };
  };

  # general os config
  security.sudo.wheelNeedsPassword = false;
  services.qemuGuest.enable = true;
  documentation.nixos.enable = false;

  # ssh server
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      AllowGroups = lib.mkDefault [ "users" ];
    };
  };

  # icinga2
  services.icinga2 = {
    enable = true;
    settings.ZoneName = "external-monitoring";
    settings.extraConstants = {
      "CustomPluginDir" = "${pkgs.custom-icinga-plugins}/bin";
    };
    settings.stanzas = {
      "object IcingaApplication \"app\"" = { };
      "object JournaldLogger \"journald\"" = { };
      "object JournaldLogger \"journald\"" = { };
      "object CheckerComponent \"checker\"" = { };
      "object NotificationComponent \"notification\"" = { };
      "object ApiListener \"api\"" = {
        accept_config = true;
        accept_commands = true;
      };
      "object IcingaDB \"icingadb\"" = {
        path = "/run/redis-icingadb/redis.sock";
      };
      "object Zone \"global-templates\"" = {
        global = true;
      };
      "object Zone \"external-monitoring\"" = {
        endpoints = [ config.networking.fqdnOrHostName ];
      };
      "object Endpoint \"${config.networking.fqdnOrHostName}\"" = { };
    };
    settings.zonedStanzas = {
      "global-templates" = {
        "object ServiceGroup \"Web\"" = ''
          assign where service.check_command == "http"
        '';
        "object ServiceGroup \"System\"" = ''
          assign where service.check_command == "load"
          assign where service.check_command == "uptime"
          assign where service.check_command == "disk"
        '';
        "object ServiceGroup \"Mail\"" = ''
          assign where service.check_command == "imap"
          assign where service.check_command == "smtp"
        '';
        "apply Service \"icinga\" to Host" = {
          "check_command" = "icinga";
          "assign where" = "host.vars.has_icinga";
        };
        "apply Service \"load\" to Host" = {
          "check_command" = "load";
          "assign where" = "host.vars.has_icinga";
        };
        "apply Service \"disk\" to Host" = {
          "check_command" = "disk";
          "assign where" = "host.vars.has_icinga";
        };
        "apply Service \"ssh\" to Host" = {
          "check_command" = "ssh";
          "assign where" = "host.vars.has_public_ssh";
        };
        "apply Service \"http-\" for (i_vhost in host.vars.http_vhosts) to Host" = ''
          display_name = i_vhost
          check_command = "http"
          vars = {
            http_vhost = i_vhost.replace("https://", "").replace("http://", "").split("/")[0]
            http_onredirect = "follow"
            http_ignore_body = true
            http_ssl = i_vhost.contains("https://")
            http_sni = i_vhost.contains("https://")
            http_ssl_force_tlsv1_or_higher = i_vhost.contains("https://")
          }
        '';
        "apply Service \"tls-\" for (i_vhost in host.vars.http_vhosts) to Host" = ''
          display_name = "TLS " + i_vhost
          check_command = "http"
          vars = {
            http_vhost = i_vhost.replace("https://", "").replace("http://", "").split("/")[0]
            http_ssl = true
            http_sni = true
            http_certificate = "2,1"
            http_ssl_force_tlsv1_or_higher = true
          }
          assign where i_vhost.contains("https://")
        '';
        "apply Service \"imaps-\" to Host" = ''
          display_name = "imaps://" + host.name
          check_command = "imap"
          vars = {
            imap_port = 993
            imap_certificate_age = 5
            imap_ssl = true
          };
          assign where host.vars.has_imap
        '';
        "apply Service \"smtp-\" to Host" = ''
          display_name = "smtp://" + host.name
          check_command = "smtp"
          vars = {
            smtp_port = 25
            smtp_helo_fqdn = "${config.networking.fqdnOrHostName}"
            smtp_starttls = true
            smtp_certificate_age = 5
          }
          assign where host.vars.has_smtp
        '';
        "apply Service \"submission-\" to Host" = ''
          display_name = "submission://" + host.name
          check_command = "smtp"
          vars = {
            smtp_port = 587
            smtp_helo_fqdn = "${config.networking.fqdnOrHostName}"
            smtp_starttls = true
            smtp_certificate_age = 5
          }
          assign where host.vars.has_smtp
        '';
        "apply Dependency \"z9-hosts-to-router\" to Host" = ''
          parent_host_name = "rt.z9.aut-num.de"
          child_host_name = host.name
          assign where host.name.contains(".z9.") && host.name != "rt.z9.aut-num.de"
        '';
      };
      "external-monitoring" = {
        "object Host \"monitoring.ex.aut-num.de\"" = {
          display_name = "Monitoring";
          address = config.networking.fqdnOrHostName;
          check_command = "hostalive";
          vars.has_icinga = true;
        };
        "object Host \"rt.z9.aut-num.de\"" = {
          display_name = "Z9 Router";
          address = "185.161.129.148";
          address6 = "2a07:c481::2:1";
          check_command = "ping";
        };
        "object Host \"jumphost.z9.aut-num.de\"" = {
          display_name = "Z9 Jumphost";
          address = "185.161.130.3";
          address6 = "2a07:c481:2:5:be24:11ff:fed8:cbc1";
          check_command = "ping";
          vars.has_public_ssh = true;
        };
        "object Host \"webhost.z9.aut-num.de\"" = {
          display_name = "Z9 Webhost";
          address = "185.161.130.7";
          address6 = "2a07:c481:2:5:be24:11ff:fed0:b3ca";
          check_command = "ping";
          vars.http_vhosts = [
            "https://lilly.hosted-on.aut-sys.de/"
            "https://skye.hosted-on.aut-sys.de/"
          ];
        };
        "object Host \"www2.z9.aut-num.de\"" = {
          display_name = "Kubernetes www2";
          address = "185.161.130.11";
          address6 = "2a07:c481:2:6::1";
          check_command = "tcp";
          vars.tcp_port = "443";
          vars.http_vhosts = [
            "https://li.lly.sh/"
            "https://pics.aut-sys.de/"
            "https://budget.aut-sys.de/"
            "https://argo.aut-sys.de/"
            "https://auth.aut-sys.de/"
            "https://prism.aut-sys.de/"
          ];
        };
        "object Host \"mx1.z9.aut-num.de\"" = {
          address = "185.161.130.10";
          address6 = "2a07:c481:2:6::";
          check_command = "tcp";
          vars.tcp_port = "993";
          vars.has_smtp = true;
          vars.has_imap = true;
        };
        "object Host \"mx2.z9.aut-num.de\"" = {
          address = "185.161.130.12";
          address6 = "2a07:c481:2:6::2";
          check_command = "tcp";
          vars.tcp_port = "993";
          vars.has_smtp = true;
          vars.has_imap = true;
        };
        "object Host \"home.lly.sh\"" = {
          address = "home.lly.sh";
          check_command = "hostalive";
          vars.http_vhosts = [
            "https://sync.home.lly.sh/"
            "https://ha.home.lly.sh/"
            "https://docs.home.lly.sh/"
            "https://unifi.home.lly.sh/"
          ];
        };
        "object Host \"bleichen.hanse.de\"" = {
          address = "212.12.50.254";
          address6 = "2a00:14b0:f001:100::fe";
          check_command = "tcp";
          vars.tcp_port = 443;
        };
        "object Host \"syncthing.z9.aut-num.de\"" = {
          address = "185.161.130.8";
          address6 = "2a07:c481:2:5:be24:11ff:fe38:a167";
          check_command = "hostalive";
          vars.http_vhosts = [
            "https://sync.aut-sys.de/"
          ];
        };
        "object Service \"matrix-server-delegation\"" = ''
          host_name = "bleichen.hanse.de"
          check_command = "http"
          vars = {
            http_vhost = "hanse.de"
            http_uri = "/.well-known/matrix/server"
            http_onredirect = "follow"
            //http_expect_body_regex = "{\"m.server\": \"matrix.hanse.de:443\"}"
            http_ssl = true
            http_sni = true
            http_certificate = "2,1"
            http_ssl_force_tlsv1_or_higher = true
          };
        '';
        "object Service \"icinga-cluster\"" = {
          host_name = config.networking.fqdnOrHostName;
          check_command = "cluster";
        };
        "object Service \"icingadb\"" = {
          host_name = config.networking.fqdnOrHostName;
          check_command = "icingadb";
        };
        "apply Service \"icinga-zone-\" for (zone in get_objects(Zone).map(zone => zone.name)) to Host" = ''
          check_command = "cluster-zone"
          vars.cluster_zone = zone
          assign where host.vars.has_icinga && host.zone == zone
        '';
        "apply Notification \"ntfy-service-state-\" for (user_name in get_objects(User).map(user => user.name)) to Service" =
          ''
            host_name = service.host_name
            service_name = service.name
            command = "ntfy-service-notification"
            users = [ user_name ]

            interval = 7d     // re-notification only once a week

            assign where get_object(User, user_name).vars.ntfy_endpoint != null && get_object(User, user_name).vars.ntfy_auth != null
          '';
        "apply Notification \"ntfy-host-state-\" for (user_name in get_objects(User).map(user => user.name)) to Host" =
          ''
            command = "ntfy-host-notification"
            users = [ user_name ]

            interval = 7d     // re-notification only once a week

            assign where get_object(User, user_name).vars.ntfy_endpoint != null && get_object(User, user_name).vars.ntfy_auth != null
          '';
      };
    };
    extraConfigFiles = [
      "${pkgs.custom-icinga-plugins}/share/icinga-objects.conf"
      config.sops.templates."icinga/apiuser.conf".path
      config.sops.secrets."icinga/secret_objects.conf".path
    ];
  };

  services.icingadb = {
    enable = true;
    settings = {
      database = {
        type = "pgsql";
        host = "/run/postgresql/";
        database = "icingadb";
        user = "icingadb";
      };
      redis = {
        host = "/run/redis-icingadb/redis.sock";
      };
      retention = {
        history-days = 30;
        sla-days = 365;
      };
    };
  };

  services.icingaweb2 = {
    enable = true;
    timezone = "Europe/Berlin";
    generalConfig = {
      global = {
        show_stacktraces = "1";
        show_application_state_messages = "1";
        config_resource = "icingaweb_db";
      };
      # security = {
      #   use_strict_csp = "1";
      # };
      logging = {
        log = "syslog";
        level = "INFO";
        application = "icingaweb2";
        facility = "user";
      };
    };
    resources = {
      icingaweb_db = {
        type = "db";
        db = "pgsql";
        host = "/run/postgresql/";
        dbname = "icingaweb2";
        username = "icingaweb2";
      };
      icingadb = {
        type = "db";
        db = "pgsql";
        host = "/run/postgresql/";
        dbname = "icingadb";
        username = "icingaweb2";
      };
    };
    authentications = {
      icingaweb2 = {
        backend = "db";
        resource = "icingaweb_db";
      };
    };
    groupBackends = {
      icingaweb2 = {
        backend = "db";
        resource = "icingaweb_db";
      };
    };
    roles = {
      "Administrators" = {
        users = "lilly";
        permissions = "*";
        groups = "Administrators";
      };
    };
    modulePackages = {
      icingadb = pkgs.icingaweb2Modules.icingadb-web;
    };
    libraryPaths = lib.mkForce {
      icinga-php-library = pkgs.icingaweb2-ipl;
      thirdparty = pkgs.icingaweb2-thirdparty;
    };
    modules.setup.enable = true;
    modules.doc.enable = true;
  };
  environment.etc = {
    "icingaweb2/modules/icingadb/config.ini".text = pkgs.lib.generators.toINI { } {
      "icingadb" = {
        resource = "icingadb";
      };
    };
    "icingaweb2/modules/icingadb/commandtransports.ini".source =
      config.sops.templates."icinga/icingaweb-commandtransports.ini".path;
    "icingaweb2/modules/icingadb/redis.ini".text = pkgs.lib.generators.toINI { } {
      icingadb.resource = "icingadb";
      redis1 = {
        # change once unix domain socket issue is fixed
        # https://github.com/Icinga/icingadb-web/issues/1443
        host = "localhost";
        port = "6380";
      };
    };
  };

  # supporting services
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  security.acme.acceptTerms = true;
  services.nginx.virtualHosts.icingaweb2 = {
    serverName = "monitoring.aut-sys.de";
    default = true;
    enableACME = true;
    forceSSL = true;
  };
  services.redis.servers."icingadb" = {
    enable = true;
    databases = 1;
    port = 6380;
  };
  services.postgresql = {
    enable = true;
    ensureUsers = [
      {
        name = "icingadb";
        ensureDBOwnership = true;
      }
      {
        name = "icingaweb2";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [
      "icingadb"
      "icingaweb2"
    ];
  };

  # required secrets
  sops = {
    secrets."icinga/apiuser_password" = { };
    secrets."icinga/secret_objects.conf" = {
      owner = "icinga2";
      group = "icinga2";
      reloadUnits = [ "icinga2.service" ];
    };
    templates."icinga/apiuser.conf" = {
      owner = "icinga2";
      group = "icinga2";
      content = ''
        object ApiUser "icingaweb2" {
          password = "${config.sops.placeholder."icinga/apiuser_password"}";
          permissions = [ "*" ];
        };
      '';
      reloadUnits = [ "icinga2.service" ];
    };
    templates."icinga/icingaweb-commandtransports.ini" = {
      owner = "icingaweb2";
      group = "icingaweb2";
      content = ''
        [icinga2-api]
        host=localhost
        password=${config.sops.placeholder."icinga/apiuser_password"}
        port=5665
        transport=api
        username=icingaweb2
      '';
    };
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "26.05";
  system.stateVersion = "26.05";
}
