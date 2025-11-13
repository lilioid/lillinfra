{ config, pkgs, ... }: {
  custom.preset = "aut-sys-vm";

  # mount shared kubernetes filesystem
  environment.systemPackages = with pkgs; [ ceph-client ];
  environment.etc."ceph/ceph.conf".text = ''
    [global]
          fsid = 13342310-b28f-4d7b-a893-af2984583a92
          mon_host = [v2:[2a07:c481:2:2::101]:3300/0,v1:[2a07:c481:2:2::101]:6789/0] [v2:[2a07:c481:2:2::102]:3300/0,v1:[2a07:c481:2:2::102]:6789/0] [v2:[2a07:c481:2:2::103]:3300/0,v1:[2a07:c481:2:2::103]:6789/0]
          keyfile=${config.sops.secrets."aut-sys-ceph/k8s/secret".path}
  '';
  fileSystems."ceph-k8s" = {
    # mount from ceph with user "k8s", cephfs named "data", and subvolume "k8s"
    device = "k8s@.data=/volumes/_nogroup/k8s/83fef1ef-824c-4815-b1f4-477a50b72376";
    mountPoint = "/srv/ceph-k8s";
    fsType = "ceph";
    options = [
      "rw"
      "noatime"
      "acl"
      "crush_location=host:pve3"
      "read_from_replica=localize"
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
      --node-label=topology.kubernetes.io/zone=z9
      --node-label=topology.aut-sys.de/hypervisor=pve3
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
