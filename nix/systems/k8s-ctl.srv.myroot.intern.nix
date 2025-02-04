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
  boot.loader.grub.device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/3abb1bda-64d0-4423-a36d-01486a41cefb";
      fsType = "ext4";
    };
  };

  custom.mailRelay.enable = true;

  # networking config
  systemd.network.networks."99-default-ether".networkConfig.IPv6AcceptRA = false;
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
    extraFlags = "--disable-helm-controller --disable=traefik --disable=servicelb --disable=local-storage --flannel-backend=vxlan --cluster-cidr 10.42.0.0/16 --service-cidr 10.43.0.0/16 --egress-selector-mode disabled --tls-san=k8s.lly.sh --node-taint node-role.kubernetes.io/control-plane=:NoSchedule";
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "24.05";
}
