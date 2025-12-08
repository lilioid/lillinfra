{ modulesPath
, config
, lib
, pkgs
, ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # boot config
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
    "hid_roccat_isku"
  ];
  boot.kernelModules = [
    "kvm-intel"
    "sg"
  ];
  boot.zfs.extraPools = [ "lillyPc" ];
  fileSystems = {
    "/" = {
      device = "lillyPc/root";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };
    "/nix" = {
      device = "lillyPc/nix";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };
    "/home" = {
      device = "lillyPc/home";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/5620-B429";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };
  swapDevices = [
    {
      device = "/dev/disk/by-partuuid/56505436-7b17-4613-8a53-0ce1cbcfb000";
      randomEncryption.enable = true;
    }
  ];
  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;
  nixpkgs.hostPlatform = "x86_64-linux";
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    configurationLimit = 10;
    useOSProber = true;
    device = "nodev";
  };
  boot.loader.efi.canTouchEfiVariables = true;
  nix.settings.system-features = [ "gccarch-znver3" ];

  virtualisation.docker.storageDriver = "zfs";

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
    heroic
  ];

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };

  # options defined by other custom modules
  custom = {
    gnomeDesktop.enable = true;
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
            { app-id="^org\\.keepassxc\\.KeePassXC$"; }
            { app-id="^org\\.telegram\\.desktop$"; }
            { app-id="^Element$"; }
            { app-id="^signal$"; }
          ];
          open-on-output = "LG Electronics 2D FHD LG TV 0x01010101";
        }
      ];
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
        address = [ "10.233.227.4/24" "2a07:c481:2:3::4/64" ];
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

  # tell taskwarrior that this is the device on which it should generate recurring tasks
  home-manager.users.lilly.programs.taskwarrior.config.recurrence = 1;

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
  services.cookied.enable = true;
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
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "24.05";
  networking.hostId = "0744a9ed";
}
