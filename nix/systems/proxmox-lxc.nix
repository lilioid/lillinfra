{ config, ... }: {
  # this is only okay because this system does not have any persistence so no data can be in an old/incompatible format
  system.stateVersion = config.system.nixos.release;
  home-manager.users.lilly.home.stateVersion = config.system.stateVersion;
}
