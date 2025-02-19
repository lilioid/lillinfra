{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
let
  renameLink = macAddr: newName: {
    matchConfig = {
      MACAddress = macAddr;
      Type = "ether";
    };
    linkConfig = {
      Name = newName;
    };
  };
in
{
  imports = [
    ../modules/hosting_guest.nix
  ];

  # boot config
  boot.loader.grub.device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/666e535a-05a0-4d37-875c-e33311442a67";
      fsType = "ext4";
    };
  };

  # networking config
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = "1";
  };

  networking.useDHCP = false;
  systemd.network = {
    enable = true;
  
    links = {
      "10-ethIntern" = renameLink "BC:24:11:94:E3:C3" "ethExtern";
      "10-ethExtern" = renameLink "BC:24:11:DE:56:03" "ethIntern";
    };

    # external interface
    networks."10-ethExtern" = {
      matchConfig.Name = "ethExtern";
      address = [
        "37.153.156.169/32"
        "2a10:9902:111:10:42:42:42:42/64"
        "2a10:9902:111:10:5054:ff:fe43:ffc6/64"
      ];
      gateway = [
        "37.153.156.168"
        "fe80::1"
      ];
      routes = [
        {
          Destination = "37.153.156.168";
        }
        {
          Destination = "37.153.156.170";
        }
      ];
      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = false;
      };
    };

    # internal interface
    networks."10-ethIntern" = {
      matchConfig.Name = "ethIntern";
      address = [ "10.0.10.2/24" ];
      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = false;
      };
    };
  };

  custom.mailRelay.enable = true;
  custom.autoUpgrade.enable = true;
  services.openssh.ports = [ 23 ];

  networking.nftables.enable = true;
  networking.nat = {
    enable = true;
    externalIP = "37.153.156.169";
    internalIPs = [ "10.0.10.0/24" ];
    externalInterface = "ethExtern";
    forwardPorts = [
      {
        # VPN
        proto = "udp";
        sourcePort = 51820;
        destination = "10.0.10.11:51820";
        loopbackIPs = [ "37.153.156.169" ];
      }
      {
        # k8s api
        proto = "tcp";
        sourcePort = 6443;
        destination = "10.0.10.15:6443";
        loopbackIPs = [ "37.153.156.169" ];
      }
      {
        # forgejo ssh
        proto = "tcp";
        sourcePort = 22;
        destination = "10.0.10.16:30022";
        loopbackIPs = [ "37.153.156.169" ];
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
    1234
  ];

  # haproxy
  services.haproxy = {
    enable = true;
    config = ''
      defaults
        timeout connect 500ms
        timeout server 1h
        timeout client 1h

      frontend http
        bind :80
        mode tcp
        use_backend ingress-http

      frontend https
        bind :443
        mode tcp
        use_backend ingress-https

      frontend pixelflut
        bind :1234
        mode tcp
        use_backend pixelflut-nodeport

      backend ingress-http
        mode tcp
        server k8s-worker1 10.0.10.16:30080 check send-proxy

      backend ingress-https
        mode tcp
        server k8s-worker1 10.0.10.16:30443 check send-proxy

      backend pixelflut-nodeport
        mode tcp
        server k8s-worker1 10.0.10.16:31234
    '';
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "24.05";
}
