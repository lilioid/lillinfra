{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
let
  data.network = import ../data/hosting_network.nix;
  data.wg_vpn = import ../data/wg_vpn.nix;
in
{
  imports = [
    ../modules/hosting_guest.nix
  ];

  # filesystem mount config
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-uuid/9124-3481";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
    "/" = {
      device = "/dev/disk/by-uuid/0ea6f61b-84b7-4903-8ba9-7dba9adba39a";
      fsType = "ext4";
    };
  };

  # enable ip forwarding so that wireguard peers can communicate with each other
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = "1";
    "net.ipv6.conf.all.forwarding" = "1";
  };

  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];

  # firewall config
  networking.firewall = {
    allowedUDPPorts = [ 51820 ];
    interfaces."wgVpn".allowedUDPPorts = [ 53 ];
  };

  # generic network config
  custom.mailRelay.enable = true;
  networking.nftables.enable = true;
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks.enp1s0 = {
      matchConfig."Type" = "ether";
      networkConfig."IPv6AcceptRA" = false;
      DHCP = "yes";
    };

    # wireguard NetDev config
    netdevs.wgVpn = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wgVpn";
      };
      wireguardConfig = {
        ListenPort = 51820;
        PrivateKeyFile = "/run/secrets/wg_vpn/privkey";
      };
      wireguardPeers = (
        builtins.map (iClient: {
          PublicKey = iClient.pubKey;
          AllowedIPs = iClient.allowedIPs;
          Endpoint = lib.mkIf (iClient.endpoint != null) iClient.endpoint;
          PersistentKeepalive = lib.mkIf iClient.keepalive 25;
        }) (lib.attrValues data.wg_vpn.knownClients)
      );
    };

    # wireguard Network config
    networks.wgVpn = {
      matchConfig = {
        Name = "wgVpn";
      };
      address = [
        "10.20.30.1/24"
        "fc10:20:30::1/64"
      ];
    };
  };

  # knot authorative dns server config
  services.knot = {
    enable = true;
    settings = {
      server = {
        listen = "127.0.0.1@8053";
      };
      template = [
        {
          id = "default";
          storage = "/etc/knot/zones";
        }
      ];
      zone = [
        {
          domain = "vpn.intern";
        }
      ];
    };
  };
  environment.etc."knot/zones/vpn.intern.zone".text = builtins.readFile ../data/zones/vpn.intern.zone;

  # knot caching resolver config
  # serves as a resolver from the root zone in additiona to diverting to the vpn.intern authorative server defined above
  services.kresd =
    let
      rpz = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/c531bbd2ef45d5dbdadc1535ad71a14bb11fe990/rpz/pro.txt";
        hash = "sha256-fsM+v7uIR4nP5lQ0jAYyui3mrHrGbr6g46yKluJlb9Y=";
      };
    in
    {
      enable = true;
      listenPlain = [
        "10.20.30.1:53"
        "[fc10:20:30::1]:53"
      ];
      extraConfig = ''
        -- forward queries belonging to internal domains to the authorative vpn.intern. server
        policy.add(policy.suffix(
          policy.STUB('127.0.0.1@8053'),
          policy.todnames({'vpn.intern'})
        ))

        -- use response policy zone
        policy.add(policy.rpz(
          policy.DENY,
          '${rpz}'
        ))
      '';
    };

  sops.secrets = {
    "wg_vpn/privkey" = {
      owner = "systemd-network";
    };
  };

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "24.05";
  system.stateVersion = "24.05";
}
