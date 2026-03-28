{
  modulesPath,
  config,
  pkgs,
  lib,
  lanzaboote,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    lanzaboote.nixosModules.lanzaboote
  ];

  # boot config
  nixpkgs.hostPlatform = "x86_64-linux";
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "thunderbolt"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-amd" ];
  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot = {
    configurationLimit = 10;
    editor = false;
  };
  boot.initrd.systemd.enable = true;
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
  };

  # partitions and fileSystems
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZVL21T0HDLU-00BLL_S75YNF0XC71406_1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "btrfs";
                  extraArgs = [ "--labels=${ config.networking.hostName }" ];
                  subvolumes = {
                    "rootfs" = {
                      mountpoint = "/";
                      mountOptions = [ "noatime" "compress=zstd" ];
                    };
                    "home" = {
                      mountpoint = "/home";
                      mountOptions = [ "noatime" "compress=zstd" ];
                    };
                    "nix-store" = {
                      mountpoint = "/nix/store";
                      mountOptions = [ "noatime" "compress=zstd" ];
                    };
                    "swap" = {
                      mountpoint = "/.swapvol";
                      swap.swapfile.size = "16G";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  hardware.bluetooth.enable = true;

  # custom battery indicator on boot
  # TODO: convert to boot.initrd.systemd unit definition
  # boot.initrd.kernelModules = [ "thinkpad_acpi" ];
  # boot.initrd.preDeviceCommands = ''
  #   # Turn on keyboard backlight before asking for drive encryption password
  #   #echo 1 > /sys/class/leds/tpacpi::kbd_backlight/brightness

  #   # show system header
  #   echo
  #   echo " _        _   _   _           _           _                        _                   "
  #   echo "| |      (_) | | | |         ( )         | |                      | |                  "
  #   echo "| |       _  | | | |  _   _  |/   ___    | |        __ _   _ __   | |_    ___    _ __  "
  #   echo "| |      | | | | | | | | | |     / __|   | |       / _\` | | '_ \  | __|  / _ \\  | '_ \\ "
  #   echo "| |____  | | | | | | | |_| |     \\__ \\   | |____  | (_| | | |_) | | |_  | (_) | | |_) |"
  #   echo "|______| |_| |_| |_|  \\__, |     |___/   |______|  \\__,_| | .__/   \\__|  \\___/  | .__/ "
  #   echo "                       __/ |                              | |                   | |    "
  #   echo "                      |___/                               |_|                   |_|    "
  #   echo
  #   echo "                                 --> found@lly.sh <--                                  "

  #   # Show battery levels
  #   echo
  #   echo "Battery level: $(cat /sys/class/power_supply/BAT0/capacity)%"
  #   echo
  # '';

  # settings defined by my own custom modules
   custom = {
     devEnv.enable = true;
     user-syncthing.enable = true;
     hardware.enableNitrokey = true;
     backup = {
       enable = true;
       destinations."rsync.net".path = "ssh://zh4525@zh4525.rsync.net/./backups/borg-repo";
       backupDirectories = [ "/home" "/root" "/var/lib/sbctl" ];
     };

     niri = {
       enable = true;
       configOverride = {
         outputs."eDP-1" = {
           position.x = 0;
           position.y = 0;
           mode.height = 1800;
           mode.width = 2880;
           mode.refresh = 90.001;
           scale = 1.5;
           focus-at-startup = true;
         };
         outputs."LG Electronics 25BL56WY 911NTFA73947" = {
           # CCCHH Werkstatt Monitor
           position.x = 0;
           position.y = -1500;
           scale = 0.8;
         };
         outputs."Optoma Corporation Optoma WXGA Q7C6351C0097" = {
           # Fux Turmzimmer
           position.x = 0;
           position.y = -1080;
           mode.width = 1920;
           mode.height = 1080;
           mode.refresh = 59.940;
         };
       };
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

       "autSysVpn" = {
         address = [ "10.233.228.2/24" "2a07:c481:2:4::2/64" ];
         peers."autSysRouter" = {
           pubKey = "3Bt7GFzA2PIzhwCWHr8D9+T19H6JMfYoH1ZrRNGMmG8=";
           endpoint = "vpn.aut-sys.de:51820";
           allowedIPs = [
             "10.233.228.0/24"    # vpn network
             "2a07:c481:2:4::/64" # vpn network
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
     prusa-slicer
     ranger
     sops
     git-crypt
     gnupg
     nftables
     file
     sbctl
     docker-compose
     minicom
   ];

   programs.steam = {
     enable = true;
     gamescopeSession.enable = true;
   };

   services.printing.enable = true;
   services.earlyoom.enable = true;
   services.resolved.enable = true;
   services.openssh.enable = true;
   services.avahi = {
     enable = true;
     nssmdns4 = true;
   };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "25.11";
  system.stateVersion = "25.11";
  networking.hostId = "1a091689";
}
