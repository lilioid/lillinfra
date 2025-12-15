{ config, pkgs, ... }: {
  custom.preset = "aut-sys-vm";

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "25.11";
  system.stateVersion = "25.11";
}
