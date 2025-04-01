{
  modulesPath,
  config,
  lib,
  pkgs,
  lanzaboote,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    lanzaboote.nixosModules.lanzaboote
  ];

  # boot config
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
    # lanzaboote is currently implemented as an alternative option to systemd-boot
    enable = lib.mkForce false;
    configurationLimit = 10;
    editor = false;
  };
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  # custom battery indicator on boot
  boot.initrd.kernelModules = [ "thinkpad_acpi" ];
  boot.initrd.preDeviceCommands = ''
    # show system header
    echo ""
    echo " _      _  _  _              _    _               _     _                    _                 "
    echo "| |    (_)| || |            | |  | |             | |   | |                  | |                "
    echo "| |     _ | || | _   _  ___ | |  | |  ___   _ __ | | __| |      __ _  _ __  | |_   ___   _ __  "
    echo "| |    | || || || | | |/ __|| |/\\| | / _ \\ | '__|| |/ /| |     / _\` || '_ \\ | __| / _ \\ | '_ \\ "
    echo "| |____| || || || |_| |\\__ \\\\  /\\  /| (_) || |   |   < | |____| (_| || |_) || |_ | (_) || |_) |"
    echo "\\_____/|_||_||_| \\__, ||___/ \\/  \\/  \\___/ |_|   |_|\\_\\\\_____/ \\__,_|| .__/  \\__| \\___/ | .__/ "
    echo "                  __/ |                                              | |                | |    "
    echo "                 |___/                                               |_|                |_|    "
    echo
    echo "                                 --> found@lly.sh <--                                  "

    # Show battery levels
    echo
    echo "Battery level: External $(cat /sys/class/power_supply/BAT1/capacity)%"
    echo "               Internal $(cat /sys/class/power_supply/BAT0/capacity)%"
    echo
  '';

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
    libreoffice-fresh
    evince
    ranger
    sops
    git-crypt
    gnupg
    nftables
    file
    sbctl
  ];

  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
  };
  services.earlyoom.enable = true;
  services.resolved.enable = true;
  services.openssh.enable = true;
  programs.gnupg.agent.enable = true;

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "24.05";
  networking.hostId = "1a091689";
}
