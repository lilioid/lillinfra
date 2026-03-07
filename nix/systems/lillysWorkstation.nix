{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # boot config
  nixpkgs.hostPlatform = "x86_64-linux";
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];
  boot.kernelModules = [
    "kvm-intel"
    "sg"
  ];
  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot = {
    enable = true;
    # enable = lib.mkForce false; # lanzaboote is currently implemented as an alternative option to systemd-boot
    configurationLimit = 10;
    editor = false;
  };
  # boot.lanzaboote = {
  #   enable = true;
  #   pkiBundle = "/etc/secureboot";
  # };
  boot.initrd.systemd = {
    enable = true;

  };
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
  };

  # partitioning and filesystems
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/ata-Samsung_SSD_860_EVO_2TB_S4X1NJ0N700005V";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "5G";
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
                  extraArgs = [ "--label=${ config.networking.hostName }" ];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/nix-store" = {
                      mountpoint = "/nix/store";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/swap" = {
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

  # hardware config
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = false;
  };

  # additional packages
  environment.systemPackages = with pkgs; [
    virt-manager
    libreoffice-fresh
    evince
    ranger
    mumble
    tree
    makemkv
    sieve-connect
    darktable
  ];

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };

  # # options defined by other custom modules
  custom = {
    devEnv.enable = true;
    user-syncthing.enable = true;
    backup = {
      enable = true;
      destinations."rsync.net".path = "ssh://zh4525@zh4525.rsync.net/./backups/borg-repo";
    };

    niri = {
      enable = true;
      configOverride = {
        outputs = {
          "Dell Inc. AW2725DF 6B87ZZ3" = {
            mode.height = 1440;
            mode.width = 2560;
            mode.refresh = 239.970;
            focus-at-startup = true;
            position.x = 0;
            position.y = 0;
          };
          "LG Electronics 2D FHD LG TV 0x01010101" = {
            mode.height = 1080;
            mode.width = 1920;
            mode.refresh = 60.0;
            position.x = 2560;
            position.y = 0;
          };
          "LG Electronics LG Ultra HD 0x00084B5E" = {
            mode.height = 2160;
            mode.width = 3840;
            mode.refresh = 59.997;
            scale = 1.5;
            position.x = -2560;
            position.y = 0;
          };
        };
      };
      additionalWindowRules = [
        {
          # open some things on the right monitor
          matches = [
            { app-id = "^org\\.keepassxc\\.KeePassXC$"; }
            { app-id = "^org\\.telegram\\.desktop$"; }
            { app-id = "^Element$"; }
            { app-id = "^signal$"; }
          ];
          open-on-output = "LG Electronics 2D FHD LG TV 0x01010101";
        }
      ];
    };

    wg.profiles = {
      "fux" = {
        address = [
          "172.17.2.251/29"
          "2a07:c481:0:2::251/64"
        ];
        peers."fuxVpn" = {
          pubKey = "bMbuZ+vYhnW2rmme8k2APLpqqMENlQHJrMza6SDEKzw=";
          endpoint = "vpn.fux-eg.net:50199";
          allowedIPs = [
            "172.16.0.0/12"
            "2a07:c481:0:1::/64"
            "2a07:c481:0:2::/64"
          ];
        };
      };

      "autSysMgmt" = {
        address = [
          "10.233.227.4/24"
          "2a07:c481:2:3::4/64"
        ];
        peers."autSysRouter" = {
          pubKey = "SySg/p4N+TEx874Rnlt/7vNmXhQPQNE+WpBDk791dww=";
          endpoint = "vpn.aut-sys.de:13231";
          allowedIPs = [
            "10.233.226.0/24" # mgmt network
            "10.233.227.0/24" # mgmt vpn
            "2a07:c481:2:2::/64" # mgmt network
            "2a07:c481:2:3::/64" # mgmt vpn
          ];
        };
      };

      "autSysVpn" = {
        address = [
          "10.233.228.4/24"
          "2a07:c481:2:4::4/64"
        ];
        peers."autSysRouter" = {
          pubKey = "3Bt7GFzA2PIzhwCWHr8D9+T19H6JMfYoH1ZrRNGMmG8=";
          endpoint = "vpn.aut-sys.de:51820";
          allowedIPs = [
            "10.233.228.0/24" # vpn network
            "2a07:c481:2:4::/64" # vpn network
          ];
        };
      };
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  services.printing.enable = true;
  services.earlyoom.enable = true;
  programs.gnupg.agent.enable = true;
  services.resolved.enable = true;
  hardware.sane = {
    enable = true;
    extraConfig."epson2" = ''
      net EPSON79DA90.home.intern
    '';
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "25.11";
  system.stateVersion = "25.11";
  networking.hostId = "0744a9ed";
}
