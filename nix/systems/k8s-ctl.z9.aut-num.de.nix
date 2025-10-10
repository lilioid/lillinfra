{ config, pkgs, lib, ... }: {
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
    6443 # k8s api server
    10250 # k8s kubelet metrics
    7946 # metallb memberlist protocol
  ];

  # kubernetes setup
  services.k3s = {
    enable = true;
    package = pkgs.k3s-custom;
    role = "server";
    clusterInit = false;
    extraFlags = builtins.replaceStrings [ "\n" ] [ " " ] ''
      --node-ip=2a07:c481:2:5:be24:11ff:fe9e:1d05,185.161.130.4
      --node-external-dns=k8s.aut-sys.de
      --node-internal-dns=k8s.z9.aut-num.de
      --disable-helm-controller
      --disable=traefik
      --disable=servicelb
      --disable=local-storage
      --flannel-backend=host-gw
      --cluster-cidr=2a07:c481:2:100::/56,10.42.0.0/16
      --service-cidr=2a07:c481:2:7::/112,10.43.0.0/16
      --egress-selector-mode=disabled
      --tls-san=k8s.aut-sys.de
      --node-taint node-role.kubernetes.io/control-plane=:NoSchedule
    '';
    environmentFile = config.sops.secrets."k3s/secret.env".path;
  };

  sops.secrets."k3s/secret.env" = {
    restartUnits = [ "k3s.service" ];
    key = "k3s/secretEnv";
  };
  sops.secrets."aut-sys-ceph/k8s/secret" = {
    sopsFile = ../data/shared-secrets/aut-sys-k8s.yml;
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "25.05";
  system.stateVersion = "25.05";
}
