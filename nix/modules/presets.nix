{ modulesPath, config, lib, ... }:
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
      # must specify the follogwing import first
      # imports = [
      #   "${modulesPath}/virtualisation/proxmox-lxc.nix"
      # ];

      #proxmoxLXC.enable = true;

      systemd.network.networks."eth0" = {
        matchConfig.Name = "eth0";
        networkConfig.DHCP = "yes";
        networkConfig.IPv6AcceptRA = "yes";
        networkConfig.DHCPPrefixDelegation = "yes";
        extraConfig = ''
          [DHCPPrefixDelegation]
          UplinkInterface = :self
        '';
      };
    })

    (lib.mkIf (cfg == "aut-sys-vm") {
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
        networkConfig.DHCPPrefixDelegation = "yes";
        extraConfig = ''
          [DHCPPrefixDelegation]
          UplinkInterface = :self
        '';
      };

      # general os config
      services.qemuGuest.enable = true;
      documentation.nixos.enable = false;

      # ssh server
      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };
      };
    })
  ];
}
