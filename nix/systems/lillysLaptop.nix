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
  hardware.bluetooth.enable = true;
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

  virtualisation.docker.storageDriver = "zfs";

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
    #gnomeDesktop.enable = true;
    niri.enable = true;
    devEnv.enable = true;
    user-syncthing.enable = true;
    backup = {
      enable = true;
      destinations."rsync.net".path = "ssh://zh4525@zh4525.rsync.net/./backups/borg-repo";
    };

    wg.profiles = {
      "fux" = {
        address = [ "172.17.2.251/29" "2a07:c481:0:2::251/64" ];
        peers."fuxVpn" = {
          pubKey = "bMbuZ+vYhnW2rmme8k2APLpqqMENlQHJrMza6SDEKzw=";
          endpoint = "vpn.fux-eg.net:50199";
          allowedIPs = [ "172.16.0.0/12" "2a07:c481:0:1::/64" "2a07:c481:0:2::/64" ];
        };
      };

      "autSysMgmt" = {
        address = [ "10.233.227.2/24" "2a07:c481:2:3::2/64" ];
        peers."autSysRouter" = {
          pubKey = "SySg/p4N+TEx874Rnlt/7vNmXhQPQNE+WpBDk791dww=";
          endpoint = "vpn.aut-sys.de:13231";
          allowedIPs = [
            "10.233.226.0/24"    # mgmt network
            "10.233.227.0/24"    # mgmt vpn
            "2a07:c481:2:2::/64" # mgmt network
            "2a07:c481:2:3::/64" # mgmt vpn
          ];
        };
      };
    };
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
    docker-compose
  ];

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };

  services.printing.enable = true;
  services.earlyoom.enable = true;
  services.resolved.enable = true;
  services.openssh.enable = true;
  programs.gnupg.agent.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  services.timesyncd.servers = [ "151.216.48.11" "151.216.48.12" ];

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "24.11";
  networking.hostId = "1a091689";
}
