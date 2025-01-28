{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
let
  data.network = import ../data/hosting_network.nix { inherit lib; };
in
{
  imports = [
    ../modules/hosting_guest.nix
  ];

  # boot config
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-uuid/9A1C-8830";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
    "/" = {
      device = "/dev/disk/by-uuid/55cc058d-7b2b-4a01-ac2c-59ba6261bc8c";
      fsType = "ext4";
    };
  };

  # networking config
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks.enp1s0 = {
      matchConfig = {
        Type = "ether";
        MACAddress = data.network.guests.mail-srv.macAddress;
      };
      DHCP = "yes";
    };
    networks.enp8s0 = {
      matchConfig = {
        Type = "ether";
        MACAddress = "52:54:00:7d:ff:7f";
      };
      DHCP = "yes";
      networkConfig = {
        IPv6AcceptRA = false;
      };
    };
  };

  # firewall
  networking.firewall = {
    # https://docs.k3s.io/installation/requirements#networking
    allowedTCPPorts = [
      10250 # kubelet metrics
      25 # mail smtp
      587 # mail submission
      993 # mail imap
      4190 # mail sieve-manage
      80 # http
      443 # https
      11334 # rspamd web port (since mailserver runs in hostNetwork kubernetes sometimes uses the node's ip address to connect to it)
    ];
    interfaces."enp8s0".allowedUDPPorts = [
      8472 # k8s flannel vxlan
    ];
  };

  # k8s setup
  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://10.0.10.15:6443";
    tokenFile = "/run/secrets/k3s/token";
  };
  sops.secrets."k3s/token" = { };

  # haproxy (for certificate generation)
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

      backend ingress-http
        mode tcp
        server s1 10.0.10.16:30080 check send-proxy

      backend ingress-https
        mode tcp
        server s1 10.0.10.16:30443 check send-proxy
    '';
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "24.05";
}
