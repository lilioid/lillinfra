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
    ../modules/vpn_client.nix
  ];

  # boot config
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "thunderbolt"
    "usb_storage"
    "sd_mod"
  ];
  # boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_6;
  boot.kernelModules = [ "kvm-amd" ];
  boot.zfs.extraPools = [ "lillysLaptop" ];
  fileSystems = {
    "/" = {
      device = "lillysLaptop/root";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };
    "/home" = {
      device = "lillysLaptop/home";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };
    "/nix" = {
      device = "lillysLaptop/nix";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/980A-2DC4";
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
  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;
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
    # Turn on keyboard backlight before asking for drive encryption password
    #echo 1 > /sys/class/leds/tpacpi::kbd_backlight/brightness

    # show system header
    echo
    echo " _        _   _   _           _           _                        _                   "
    echo "| |      (_) | | | |         ( )         | |                      | |                  "
    echo "| |       _  | | | |  _   _  |/   ___    | |        __ _   _ __   | |_    ___    _ __  "
    echo "| |      | | | | | | | | | |     / __|   | |       / _\` | | '_ \  | __|  / _ \\  | '_ \\ "
    echo "| |____  | | | | | | | |_| |     \\__ \\   | |____  | (_| | | |_) | | |_  | (_) | | |_) |"
    echo "|______| |_| |_| |_|  \\__, |     |___/   |______|  \\__,_| | .__/   \\__|  \\___/  | .__/ "
    echo "                       __/ |                              | |                   | |    "
    echo "                      |___/                               |_|                   |_|    "
    echo
    echo "                                 --> found@lly.sh <--                                  "

    # Show battery levels
    echo
    echo "Battery level: $(cat /sys/class/power_supply/BAT0/capacity)%"
    echo
  '';

  # settings defined by my own custom modules
  custom = {
    gnomeDesktop.enable = true;
    devEnv.enable = true;
    devEnv.enableFuxVpn = true;
    user-syncthing.enable = true;
    backup.enable = true;
    gaming.enable = true;
  };

  # additional packages
  environment.systemPackages = with pkgs; [
    nixpkgs-fmt
    virt-manager
    libreoffice-fresh
    openscad
    freecad
    prusa-slicer
    evince
    ranger
    sops
    git-crypt
    gnupg
    sieveshell
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
  services.printing.enable = true;
  services.earlyoom.enable = true;
  services.resolved.enable = true;
  services.openssh.enable = true;
  programs.gnupg.agent.enable = true;

  # fux vpn connection
  sops.secrets."wg_fux/privkey" = { };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "24.11";
  networking.hostId = "1a091689";
}
