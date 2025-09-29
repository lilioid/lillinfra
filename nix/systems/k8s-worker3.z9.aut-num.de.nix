{ config, ... }: {
  custom.preset = "aut-sys-vm";

  networking.firewall.allowedTCPPorts = [
    10250 # k8s kubelet metrics
  ];

  # kubernetes setup
  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://k8s-ctl.z9.aut-num.de:6443";
    extraFlags = builtins.replaceStrings [ "\n" ] [ " " ] ''
      --node-ip=2a07:c481:2:5:be24:11ff:feac:5082
      --node-internal-dns=k8s-worker3.z9.aut-num.de
    '';
    tokenFile = config.sops.secrets."k3s/token".path;
  };

  sops.secrets."k3s/token" = {
    sopsFile = ../data/shared-secrets/aut-sys-k8s.yml;
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "25.05";
  system.stateVersion = "25.05";
}
