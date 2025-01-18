{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
let
  data.network = import ../data/hosting_network.nix { inherit lib; };

  capitalize =
    str:
    lib.concatStrings [
      (lib.strings.toUpper (builtins.substring 0 1 str))
      (builtins.substring 1 (lib.stringLength str) str)
    ];

  mkBridgeNetdev = name: {
    netdevConfig = {
      Name = name;
      Kind = "bridge";
    };
    bridgeConfig = {
      STP = true;
    };
  };

  mkBridgeNetwork = name: {
    matchConfig = {
      Name = builtins.substring 0 15 name;
      Kind = "bridge";
    };
    linkConfig = {
      RequiredForOnline = false;
      ActivationPolicy = "up";
    };
    networkConfig = {
      LinkLocalAddressing = false;
      ConfigureWithoutCarrier = true;
    };
  };

  mkVeth = name: {
    netdevConfig = {
      Name = "${builtins.substring 0 (15 - 3) name}-up";
      Description = "veth device for connecting a tenant (down) to brVMs (up)";
      Kind = "veth";
    };
    peerConfig = {
      Name = "${builtins.substring 0 (15 - 5) name}-down";
    };
  };

  mkVethConnUp = name: vlan: {
    matchConfig = {
      Name = config.systemd.network.netdevs."${name}".netdevConfig.Name;
    };
    networkConfig = {
      Bridge = config.systemd.network.netdevs.brVMs.netdevConfig.Name;
    };
    bridgeVLANs = [
      {
        VLAN = vlan;
        EgressUntagged = vlan;
        PVID = vlan;
      }
    ];
  };

  mkVethConnDown = vethName: brName: {
    matchConfig = {
      Name = config.systemd.network.netdevs."${vethName}".peerConfig.Name;
    };
    networkConfig = {
      Bridge = config.systemd.network.netdevs."${brName}".netdevConfig.Name;
    };
  };
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # boot config
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ehci_pci"
    "ahci"
    "usbhid"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.loader.grub = {
    enable = true;
    device = "/dev/disk/by-id/ata-WDC_WD120EFBX-68B0EN0_D7HE49WN";
  };
  boot.zfs.extraPools = [ "hdd" ];
  fileSystems = {
    "/" = {
      device = "hdd/root";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };
    "/nix" = {
      device = "hdd/nix";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/C85B-5816";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };
  swapDevices = [
    {
      device = "/dev/disk/by-uuid/58ccf5a8-6b0f-45b3-bfe0-fe9db08b3338";
    }
  ];

  # networking config
  networking.useDHCP = false;
  custom.mailRelay.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  systemd.network = {
    enable = true;

    netdevs =
      lib.mergeAttrs
        # statically defined netdevs
        {
          # define a bridge device for physical network connections
          brMyRoot = {
            netdevConfig = {
              Name = "brMyRoot";
              Description = "The bridge device connected to the physical network";
              Kind = "bridge";
              MACAddress = "0c:c4:7a:8e:25:ae";
            };
            bridgeConfig = {
              MulticastSnooping = false;
            };
            bridgeConfig = {
              STP = true;
            };
          };

          # define a 'master' bridge device to which the routing vm and all tenant bridges are connected
          brVMs = {
            netdevConfig = {
              Name = "brVMs";
              Kind = "bridge";
            };
            bridgeConfig = {
              STP = true;
              VLANFiltering = true;
            };
          };
        }
        # netdevs generated from hosting_network.nix
        (
          lib.attrsets.concatMapAttrs (name: data: {
            "br${capitalize name}" = mkBridgeNetdev "br${capitalize name}";
            "veth${capitalize name}" = mkVeth "veth${capitalize name}";
          }) data.network.tenants
        );

    networks =
      lib.mergeAttrs
        # statically defined network configs
        {
          # instruct the physical ethernet adapter to bring up the brMyRoot bridge device
          ethMyRoot = {
            matchConfig = {
              Type = "ether";
              MACAddress = "0c:c4:7a:8e:25:ae";
            };
            networkConfig = {
              Bridge = config.systemd.network.netdevs.brMyRoot.netdevConfig.Name;
            };
          };

          # assign IP addresses for the server itself on the bridge device
          brMyRoot = {
            matchConfig = {
              Name = config.systemd.network.netdevs.brMyRoot.netdevConfig.Name;
            };
            address = [
              "37.153.156.125/24"
              "2a10:9906:1002:0:125::125/64"
            ];
            gateway = [
              "37.153.156.1"
              "2a10:9906:1002::1"
            ];
            routes =
              [
                {
                  # rt-hosting IPv4 can always be reached
                  Destination = data.network.rt-hosting.ip4;
                }
              ]
              ++ builtins.map
                # guestIPs can be reached via rt-hosting
                (i: {
                  Destination = i;
                  Gateway = data.network.guests.rt-hosting.ipv4;
                })
                data.network.guestIPs;
          };

          # an empty network on the VM bridge
          brVMs = mkBridgeNetwork "brVMs";
        }
        # network configs generated from hosting_network.nix
        (
          lib.attrsets.concatMapAttrs (name: data: {
            "br${capitalize name}" =
              mkBridgeNetwork
                config.systemd.network.netdevs."br${capitalize name}".netdevConfig.Name;
            "veth${capitalize name}-up" = mkVethConnUp "veth${capitalize name}" data.tenantId;
            "veth${capitalize name}-down" =
              mkVethConnDown "veth${capitalize name}"
                config.systemd.network.netdevs."br${capitalize name}".netdevConfig.Name;
          }) data.network.tenants
        );
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = "1";
    "net.ipv6.conf.all.forwarding" = "1";
    "vm.swappiness" = "0";
  };

  # regularly update my own installer image
  systemd.timers.build-custom-installer = {
    name = "build-custom-installer.timer";
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "daily";
  };
  systemd.services.build-custom-installer = {
    name = "build-custom-installer.service";
    path = with pkgs; [ nix coreutils git ];
    script = ''
      RESULT=$(nix build --no-link --print-out-paths "git+https://git.lly.sh/lilly/lillinfra.git#installer")
      ln -sf $RESULT/iso/*.iso /var/lib/libvirt/images/nixos-custom-lilly.iso
    '';
  };
  
  #systemd.timers.download-nixos-installer = {
  #  name = "download-nixos-installer.timer";
  #  wantedBy = [ "timers.target" ];
  #  timerConfig = {
  #    OnActiveSec = "0";
  #    OnCalendar = "24hr";
  #  };
  #};
  #systemd.services.download-nixos-installer = {
  #  name = "download-nixos-installer.service";
  #  path = [ pkgs.curl ];
  #  script = "curl -sSL https://channels.nixos.org/nixos-24.05/latest-nixos-minimal-x86_64-linux.iso -o /var/lib/libvirt/images/nixos-installer-x86_64-linux.iso";
  #};
  #systemd.timers.download-debian-installer = {
  #  name = "download-debian-installer.timer";
  #  wantedBy = [ "timers.target" ];
  #  timerConfig = {
  #    OnActiveSec = "0";
  #    OnCalendar = "24hr";
  #  };
  #};
  #systemd.services.download-debian-installer = {
  #  name = "download-debian-installer.service";
  #  path = [ pkgs.curl ];
  #  script = "curl -sSL https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso -o /var/lib/libvirt/images/debian-12-amd64-netinst.iso";
  #};

  virtualisation.libvirtd = {
    enable = true;
    onShutdown = "shutdown";
    parallelShutdown = 10;
    hooks.qemu =
      let
        configure-bridge-vlan-port = pkgs.writeShellApplication {
          name = "qemu-configure-bridge-vlan-port";
          runtimeInputs = with pkgs; [ xmlstarlet ];
          text = ''
            # Docs: https://www.libvirt.org/hooks.html#etc-libvirt-hooks-network
            #
            # Assigns configugres the brVMs network device to allow all tenant VLANs to be forwarded to the routing vm
            # DOMAIN=$1
            OPERATION=$2
            # SUB_OPERATION=$3

            echo "DOMAIN=$1    OPERATION=$2    SUB_OPERATION=$3" >&2
            DOMAIN_XML="$(xmlstarlet select -t -c /domain -)"

            case $OPERATION in
              start)
                IFACE_COUNT=0
                while true; do
                  ((++IFACE_COUNT))
                  IFACE_XML="$(echo "$DOMAIN_XML" | xmlstarlet select -t -c "/domain/devices/interface[$IFACE_COUNT]" || exit 0)"
                  if [[ -z "$IFACE_XML" ]]; then
                      # finished
                      exit 0
                  fi

                  echo "$IFACE_XML" >&2
                  SOURCE_IFACE_NAME="$(echo "$IFACE_XML" | xmlstarlet select -t -v /interface/source/@network)"
                  TARGET_IFACE_NAME="$(echo "$IFACE_XML" | xmlstarlet select -t -v /interface/target/@dev)"
                  if [[ "$SOURCE_IFACE_NAME" = "brVMs" ]]; then
                    echo "Enabling VLANs 10-99 for bridge port $TARGET_IFACE_NAME" >&2
                    bridge vlan add vid 10-99 dev "$TARGET_IFACE_NAME"
                  else
                    echo "Ignoring interface $TARGET_IFACE_NAME (bridged to $SOURCE_IFACE_NAME)" >&2
                  fi
                done
                ;;
              *)
                echo "qemu hook does not handle operation $OPERATION*" >&2
                ;;
            esac
          '';
        };
      in
      {
        configure-bridge-vlan-port = "${configure-bridge-vlan-port}/bin/qemu-configure-bridge-vlan-port";
      };
  };
  users.users.lilly.extraGroups = [ "libvirtd" ];

  environment.systemPackages = with pkgs; [
    bridge-utils
    traceroute
  ];

  # backup config
  custom.backup.rsync-net = {
    enable = true;
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "23.11";
  networking.hostId = "eaad9974";
}
