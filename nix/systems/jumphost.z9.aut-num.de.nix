{ pkgs, lib, config, ... }: {
  custom.preset = "aut-sys-lxc";

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.11";
  system.stateVersion = "24.11";
}
