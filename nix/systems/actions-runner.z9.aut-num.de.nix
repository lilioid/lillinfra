{ config, pkgs, lib, ... }: {
  custom.preset = "aut-sys-vm";

  networking.nameservers = [ "2620:fe::fe" ];

  # setup runner
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  networking.firewall.allowedTCPPorts = [ 45540 45541 ];
  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances."git.hanse.de" = {
      enable = true;
      name = "aut-sys-runner";
      tokenFile = config.sops.templates."forgejo-actions-runner/tokenFile".path;
      url = "https://git.hanse.de/";
      labels = [
        "debian-latest:docker://node:current"
        "alpine-latest:docker://node:current-alpine"
      ];
      settings = {
        runner.capacity = 1;
        cache.proxy_port = 45540;
        container = {
          docker_host = "automount";
          valid_volumes = [ "shared-nix-store" ];
        };
      };
    };
    instances."git.hanse.de-nix" = {
      enable = true;
      name = "aut-sys-runner--nix";
      tokenFile = config.sops.templates."forgejo-actions-runner/tokenFile".path;
      url = "https://git.hanse.de/";
      labels = [
        "nixos-latest:docker://git.hanse.de/lilly/lillinfra-nix-builder"
      ];
      settings = {
        runner.capacity = 1;
        cache.proxy_port = 45541;
        container = {
          privileged = true;
          docker_host = "automount";
          valid_volumes = ["shared-nix-store"];
        };
      };
    };
  };

  # provide registration token to runner
  sops.secrets."forgejo-actions-runner/registration-token" = {};
  sops.templates."forgejo-actions-runner/tokenFile".content = ''
    TOKEN=${config.sops.placeholder."forgejo-actions-runner/registration-token"}
  '';

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "25.11";
  system.stateVersion = "25.11";
}
