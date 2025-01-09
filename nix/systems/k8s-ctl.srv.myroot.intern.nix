{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
let
  data.network = import ../data/hosting_network.nix;
in
{
  imports = [
    ../modules/hosting_guest.nix
  ];

  # boot config
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-uuid/90B5-97F3";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
    "/" = {
      device = "/dev/disk/by-uuid/ca0700a0-ae52-4fae-ac7e-562b8ec6ea16";
      fsType = "ext4";
    };
    "/srv/data/k8s" = {
      device = "10.0.10.14:/srv/data/k8s";
      fsType = "nfs";
      options = [
        "defaults"
        "_netdev"
      ];
    };
  };

  # networking config
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks.enp1s0 = {
      matchConfig = {
        Type = "ether";
        MACAddress = "52:54:00:58:93:1a";
      };
      networkConfig = {
        IPv6AcceptRA = false;
      };
      DHCP = "yes";
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      6443 # k8s api server
      10250 # k8s kubelet metrics
    ];
    allowedUDPPorts = [
      8472 # k8s flannel vxlan
    ];
  };

  # kubernetes setup
  services.k3s = {
    enable = true;
    role = "server";
    clusterInit = false;
    extraFlags = "--disable-helm-controller --disable=traefik --disable=servicelb --disable=local-storage --flannel-backend=vxlan --cluster-cidr 10.42.0.0/16 --service-cidr 10.43.0.0/16 --egress-selector-mode disabled --tls-san=k8s.ftsell.de --node-taint node-role.kubernetes.io/control-plane=:NoSchedule";
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "24.05";
}
