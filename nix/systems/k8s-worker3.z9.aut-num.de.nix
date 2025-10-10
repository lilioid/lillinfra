{ config, pkgs, ... }: {
  custom.preset = "aut-sys-vm";

  environment.systemPackages = with pkgs; [ ceph-client ];
  fileSystems."ceph-k8s" = {
    device = "[2a07:c481:2:2::101],[2a07:c481:2:2::102],[2a07:c481:2:2::103]:/volumes/k8s/";
    mountPoint = "/srv/ceph-k8s";
    fsType = "ceph";
    options = [
      "name=k8s"
      "secretfile=${config.sops.secrets."aut-sys-ceph/k8s/secret".path}"
      "fsid=13342310-b28f-4d7b-a893-af2984583a92"
      "fs=data"
      "rw"
      "noatime"
      "acl"
    ];
    neededForBoot = false;
    noCheck = true;
  };

  networking.firewall.allowedTCPPorts = [
    10250 # k8s kubelet metrics
    7946  # metallb memberlist protocol
  ];

  # kubernetes setup
  services.k3s = {
    enable = true;
    package = pkgs.k3s-custom;
    role = "agent";
    serverAddr = "https://k8s-ctl.z9.aut-num.de:6443";
    extraFlags = builtins.replaceStrings [ "\n" ] [ " " ] ''
      --node-ip=2a07:c481:2:5:be24:11ff:feac:5082,185.161.130.6
      --node-internal-dns=k8s-worker3.z9.aut-num.de
    '';
    tokenFile = config.sops.secrets."k3s/token".path;
  };

  sops.secrets."k3s/token" = {
    sopsFile = ../data/shared-secrets/aut-sys-k8s.yml;
  };
  sops.secrets."aut-sys-ceph/k8s/secret" = {
    sopsFile = ../data/shared-secrets/aut-sys-k8s.yml;
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "25.05";
  system.stateVersion = "25.05";
}
