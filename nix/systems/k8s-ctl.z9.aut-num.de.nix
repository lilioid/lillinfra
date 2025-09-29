{ config, ... }: {
  custom.preset = "aut-sys-vm";

  networking.firewall.allowedTCPPorts = [
    6443 # k8s api server
    10250 # k8s kubelet metrics
  ];

  # kubernetes setup
  services.k3s = {
    enable = true;
    role = "server";
    clusterInit = false;
    extraFlags = builtins.replaceStrings [ "\n" ] [ " " ] ''
      --node-ip=2a07:c481:2:5:be24:11ff:fe9e:1d05
      --node-external-dns=k8s.aut-sys.de
      --node-internal-dns=k8s.z9.aut-num.de
      --disable-helm-controller
      --disable=traefik
      --disable=servicelb
      --disable=local-storage
      --flannel-backend=host-gw
      --cluster-cidr=2a07:c481:2:6::/64
      --service-cidr=2a07:c481:2:7::/112
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

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "25.05";
  system.stateVersion = "25.05";
}
