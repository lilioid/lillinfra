{
  modulesPath,
  config,
  lib,
  pkgs,
  home-manager,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../modules/base_system.nix
    ../modules/dev_env.nix
    ../modules/syncthing.nix
    ../modules/vpn_client.nix
  ];

  # boot config
  #boot.initrd.systemd.enable = true;
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_6;
  boot.kernelModules = [ "kvm-intel" ];
  boot.zfs.extraPools = [ "nvme" ];
  fileSystems = {
    "/" = {
      device = "nvme/root";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };
    "/home" = {
      device = "nvme/home";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };
    "/nix" = {
      device = "nvme/nix";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/5C6D-BE54";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };
  swapDevices = [
    {
      device = "/dev/nvme0n1p2";
      randomEncryption.enable = true;
    }
  ];
  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;
  nixpkgs.hostPlatform = "x86_64-linux";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
    editor = false;
  };

  # settings defined by my own custom modules
  custom = {
    gnomeDesktop.enable = true;
    devEnv.enable = true;
    user-syncthing.enable = true;
    backup.rsync-net = {
      enable = true;
      repoPath = "./backups/private-systems";
    };
  };

  # additional packages
  environment.systemPackages = with pkgs; [
    nixpkgs-fmt
    virt-manager
    libreoffice-fresh
    evince
    ranger
    sops
    git-crypt
    gnupg
    sieveshell
    nftables
    file
  ];

  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
  };
  services.printing.enable = true;
  services.earlyoom.enable = true;
  services.resolved.enable = true;
  programs.gnupg.agent.enable = true;

  sops.age.keyFile = /home/lilly/.config/sops/age/keys.txt;

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "24.05";
  networking.hostId = "1a091689";
}
