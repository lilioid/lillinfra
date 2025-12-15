{ config, pkgs, lib, ... }: {
  custom.preset = "aut-sys-vm";

  networking.nameservers = [ "2620:fe::fe" ];

  # setup runner
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  systemd.services."gitea-actions-runner".description = lib.mkForce "Forgejo Actions Runner";
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
        "nixos-latest:docker://nixos/nix"
      ];
      settings = {
        container = {
          docker_host = "automount";
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
