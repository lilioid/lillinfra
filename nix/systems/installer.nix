{
  config,
  modulesPath,
  lib,
  pkgs,
  home-manager,
  sops-nix,
  lix,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  environment.systemPackages = with pkgs; [
    curl
    git
    keyutils
    helix
    tmux
    disko
  ];

  networking.hostName = lib.mkForce "lillys-nixos-installer";
  system.installer.channel.enable = true;

  # use iwd instead of wpa_supplicant because the CLI is more user-friendly
  networking.wireless.enable = false;
  networking.wireless.iwd.enable = true;

  # configure my own user account in the installer
  services.getty.autologinUser = lib.mkForce "lilly";

  # this is only okay because the installer does not have any persistence so no data can be in an old/incompatible format
  system.stateVersion = config.system.nixos.release;
  home-manager.users.lilly.home.stateVersion = config.system.stateVersion;
}
