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
      device = "/dev/disk/by-uuid/94A7-6995";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
    "/" = {
      device = "/dev/disk/by-uuid/4e0b7ea5-8c74-478f-a4e3-ddc5691e4065";
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
  custom.mailRelay.enable = true;
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks.enp1s0 = {
      matchConfig = {
        Type = "ether";
        MACAddress = "52:54:00:e6:1f:51";
      };
      networkConfig = {
        IPv6AcceptRA = false;
      };
      DHCP = "yes";
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      10250 # k8s kubelet metrics
      30080 # ingress http
      30443 # ingress https
      30022 # forgejo ssh
      31234 # pixelflut
    ];
    allowedUDPPorts = [
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

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "24.05";
}
