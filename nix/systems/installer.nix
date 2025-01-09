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
    home-manager.nixosModules.default
    sops-nix.nixosModules.default
    lix.nixosModules.lixFromNixpkgs
    ../modules/base_system.nix
    ../modules/user_lilly.nix
    ../modules/gnome.nix
    ../modules/dev_env.nix
  ];

  environment.systemPackages = with pkgs; [
    curl
    git
    keyutils
    helix
  ];

  networking.hostName = "nixos-installer";
  networking.domain = "lilly.intern";
  system.installer.channel.enable = true;

  # use iwd instead of wpa_supplicant because the CLI is more user-friendly
  networking.wireless.enable = false;
  networking.wireless.iwd.enable = true;

  # configure my own user account in the installer
  custom.user.enable = true;
  services.getty.autologinUser = lib.mkForce "lilly";

  # this is only okay because the installer does not have any persistence so no data can be in an old/incompatible format
  system.stateVersion = config.system.nixos.release;
  home-manager.users.lilly.home.stateVersion = config.system.stateVersion;
}
