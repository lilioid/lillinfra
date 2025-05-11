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
  boot.loader.grub.device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/c5d24ed6-ee06-4634-b4b6-da1bb26c38b6";
      fsType = "ext4";
    };
  };

  # networking config
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks."80-intern-ether" = {
      matchConfig = {
        Type = "ether";
        MACAddress = "BC:24:11:D0:67:E4";
      };
      DHCP = "yes";
      networkConfig.IPv6AcceptRA = false;
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
    allowedUDPPorts = [
      8472 # k8s flannel vxlan
    ];
  };

  # k8s setup
  services.k3s = {
    enable = true;
    role = "agent";
    extraFlags = "--node-taint ip-reputation=mailserver:NoSchedule --node-ip=10.0.10.12 --node-external-ip=10.0.10.12";
    serverAddr = "https://10.0.10.15:6443";
    tokenFile = config.sops.secrets."k3s/token".path;
  };
  sops.secrets."k3s/token" = {
    sopsFile = ../data/shared-secrets/k8s-node.yml;
  };

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
