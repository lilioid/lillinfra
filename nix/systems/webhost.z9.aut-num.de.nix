{ pkgs, lib, ... }: {
  custom.preset = "aut-sys-lxc";

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "li@lly.sh";

  custom.webhosting.users.skye = {
    sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC2vP9rQP6f6o61VUssBFvgY+O2sZ7T4OGaNkJTAk8G2 skye";
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "24.05";
}
