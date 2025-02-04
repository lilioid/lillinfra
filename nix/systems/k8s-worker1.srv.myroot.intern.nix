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
      device = "/dev/disk/by-uuid/935021dd-8c84-40a3-8782-91e77ca84ef5";
      fsType = "ext4";
    };
  };

  # networking config
  custom.mailRelay.enable = true;
  systemd.network.networks."99-default-ether".networkConfig.IPv6AcceptRA = false;

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
