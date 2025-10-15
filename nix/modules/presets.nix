{ modulesPath, config, lib, pkgs, ... }:
let
  cfg = config.custom.preset;
in
{
  options = with lib.options; {
    custom.preset = mkOption {
      description = "Choose a configuration preset based on the systems hosting environment";
      default = "standalone";
      type = lib.types.enum [ "standalone" "hosting" "home" "aut-sys-lxc" "aut-sys-vm" ];
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg == "standalone") { })

    (lib.mkIf (cfg == "hosting") {
      #      imports = [
      #        (modulesPath + "/profiles/qemu-guest.nix")
      #      ];
      #
      #      # boot config
      #      boot.initrd.systemd.enable = true;
      #      boot.initrd.availableKernelModules = [
      #        "ahci"
      #        "xhci_pci"
      #        "virtio_pci"
      #        "sr_mod"
      #        "virtio_blk"
      #      ];
      #      boot.initrd.kernelModules = [ ];
      #      boot.kernelModules = [ "kvm-intel" ];
      #      boot.extraModulePackages = [ ];
      #      boot.loader.grub = {
      #        enable = true;
      #        extraEntries = ''
      #          menuentry "Firmware Setup" {
      #            fwsetup
      #          }
      #        '';
      #      };
      #
      #      # general os config
      #      services.qemuGuest.enable = true;
      #      documentation.nixos.enable = false;
      #
      #      # configure systemd-networkd to listen for DHCP and router advertisements on all ethernet interfaces by default
      #      networking.useDHCP = false;
      #      systemd.network = {
      #        enable = true;
      #        networks."99-default-ether" = {
      #          matchConfig = {
      #            Type = "ether";
      #            Kind = "!veth";
      #          };
      #          DHCP = "yes";
      #          networkConfig.IPv6AcceptRA = lib.mkDefault true;
      #        };
      #      };
      #
      #      # ssh server
      #      services.openssh = {
      #        enable = true;
      #        settings = {
      #          PermitRootLogin = "no";
      #          PasswordAuthentication = false;
      #        };
      #      };
    })

    (lib.mkIf (cfg == "home") {
      #      imports = [
      #        (modulesPath + "/profiles/qemu-guest.nix")
      #      ];
      #
      #      # boot config
      #      boot.initrd.systemd.enable = true;
      #      boot.initrd.availableKernelModules = [
      #        "ahci"
      #        "xhci_pci"
      #        "virtio_pci"
      #        "sr_mod"
      #        "virtio_blk"
      #      ];
      #      boot.initrd.kernelModules = [ ];
      #      boot.kernelModules = [ "kvm-intel" ];
      #      boot.extraModulePackages = [ ];
      #      boot.loader.systemd-boot = {
      #        enable = true;
      #        editor = false;
      #      };
      #
      #      # general os config
      #      services.qemuGuest.enable = true;
      #      documentation.nixos.enable = false;
      #
      #      # configure systemd-networkd to listen for DHCP and router advertisements on all ethernet interfaces by default
      #      networking.useDHCP = false;
      #      systemd.network = {
      #        enable = true;
      #        networks."99-default-ether" = {
      #          matchConfig = {
      #            Type = "ether";
      #            Kind = "!veth";
      #          };
      #          DHCP = "yes";
      #          networkConfig.IPv6AcceptRA = lib.mkDefault true;
      #        };
      #      };
      #
      #      # ssh server
      #      services.openssh = {
      #        enable = true;
      #        settings = {
      #          PermitRootLogin = "no";
      #          PasswordAuthentication = false;
      #        };
      #      };
    })

    (lib.mkIf (cfg == "aut-sys-lxc") {
      system.nixos.tags = [
        "aut-sys"
        "lxc"
      ];

      boot.postBootCommands = ''
        # After booting, register the contents of the Nix store in the Nix
        # database.
        if [ -f /nix-path-registration ]; then
          ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration &&
          rm /nix-path-registration
        fi

        # nixos-rebuild also requires a "system" profile
        ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
      '';

      boot = {
        isContainer = true;
        loader.initScript.enable = true;
      };

      console.enable = true;

      networking = {
        useDHCP = false;
        useHostResolvConf = false;
        useNetworkd = true;
      };

      # unprivileged LXCs can't set net.ipv4.ping_group_range
      security.wrappers.ping = {
        owner = "root";
        group = "root";
        capabilities = "cap_net_raw+p";
        source = "${pkgs.iputils.out}/bin/ping";
      };
      security.sudo.wheelNeedsPassword = false;

      services.openssh = {
        enable = lib.mkDefault true;
        startWhenNeeded = lib.mkDefault true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
          AllowGroups = lib.mkDefault [ "users" ];
        };
      };

      systemd = {
        mounts = [
          {
            enable = false;
            where = "/sys/kernel/debug";
          }
        ];

        # By default only starts getty on tty0 but first on LXC is tty1
        services."autovt@".unitConfig.ConditionPathExists = [
          ""
          "/dev/%I"
        ];

        # These are disabled by `console.enable` but console via tty is the default in Proxmox
        services."getty@tty1".enable = lib.mkForce true;
        services."autovt@".enable = lib.mkForce true;

        # configure networking used in aut-sys
        network.networks."eth0" = {
          matchConfig.Name = "eth0";
          networkConfig.DHCP = "yes";
          networkConfig.IPv6AcceptRA = "yes";
        };
      };
    })

    (lib.mkIf (cfg == "aut-sys-vm") {
      system.nixos.tags = [
        "aut-sys"
        "vm"
      ];

      # boot config
      boot.initrd.systemd.enable = true;
      boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ ];
      boot.extraModulePackages = [ ];

      # configure systemd-boot bootloader
      boot.loader.systemd-boot = {
        enable = true;
        editor = false;
        configurationLimit = 4;
      };

      # partitioning and filesystems
      disko.devices = lib.mkDefault {
        disk = {
          system = {
            type = "disk";
            device = lib.mkDefault "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
            content = {
              type = "gpt";
              partitions = {
                esp = {
                  type = "ef00";
                  start = "1M";
                  size = "500M";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                    mountOptions = [ "umask=0077" ];
                  };
                };
                swap = {
                  size = lib.mkDefault "4G";
                  content = {
                    type = "swap";
                    discardPolicy = "both";
                  };
                };
                root = {
                  type = "8300";
                  size = "100%";
                  content = {
                    type = "filesystem";
                    format = "ext4";
                    mountpoint = "/";
                    mountOptions = [
                      "defaults"
                      "noatime"
                    ];
                  };
                };
              };
            };
          };
        };
      };

      # network config
      systemd.network.networks."eth0" = {
        matchConfig.Name = "eth0";
        networkConfig.DHCP = "yes";
        networkConfig.IPv6AcceptRA = "yes";
      };

      # general os config
      security.sudo.wheelNeedsPassword = false;
      services.qemuGuest.enable = true;
      documentation.nixos.enable = false;

      # ssh server
      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
          AllowGroups = lib.mkDefault [ "users" ];
        };
      };
    })
  ];
}
