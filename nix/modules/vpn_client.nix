{
  config,
  lib,
  pkgs,
  ...
}:
let
  data.wg_vpn = import ../data/wg_vpn.nix;

  selfClientConf = data.wg_vpn.knownClients."${config.networking.fqdnOrHostName}";

  isIp4Addr = addr: !(isIp6Addr addr);
  isIp6Addr = addr: lib.strings.hasInfix ":" addr;

  # decide how the wireguard connection is managed based on which other software is enabled
  implMode =
    if config.systemd.network.enable then
      "systemd-networkd"
    else if config.networking.networkmanager.enable then
      "network-manager"
    else
      "wg-quick";
in
{
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];

  # systemd-networkd based implementation
  systemd.network = lib.mkIf (implMode == "systemd-networkd") {
    netdevs."wgVpn" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wgVpn";
      };
      wireguardConfig = {
        ListenPort = 51820;
        PrivateKeyFile = "/run/secrets/wg_vpn/privkey";
      };
      wireguardPeers = (
        builtins.map (iServer: {
          PublicKey = iServer.pubKey;
          AllowedIPs = iServer.allowedIPs;
          Endpoint = iServer.endpoint;
          PersistentKeepalive = lib.mkIf selfClientConf.keepalive 25;
        }) (lib.attrValues data.wg_vpn.knownServers)
      );
    };

    networks.wgVpn = {
      matchConfig = {
        Name = "wgVpn";
      };
      address = selfClientConf.allowedIPs;
      routes = (
        lib.flatten (
          builtins.map (
            iServer:
            builtins.map (iIP: {
              Destination = iIP;
            }) iServer.allowedIPs
          ) (lib.attrValues data.wg_vpn.knownServers)
        )
      );
    };
  };

  # network-manager based implementation
  networking.networkmanager = lib.mkIf (implMode == "network-manager") {
    ensureProfiles.profiles."wgVpn" =
      lib.mergeAttrs
        {
          connection = {
            id = "wgVpn";
            type = "wireguard";
            autoconnect = true;
            interface-name = "wgVpn";
            permissions = "user:lilly:;";
          };
          wireguard = {
            private-key-flags = 1;
          };
          ipv4 =
            lib.mergeAttrs
              {
                method = "manual";
                dns = builtins.head (builtins.filter isIp4Addr data.wg_vpn.network.dns);
                dns-search = data.wg_vpn.network.searchDomain;
              }
              (
                lib.attrsets.listToAttrs (
                  lib.imap1 (i: addr: {
                    name = "address${builtins.toString i}";
                    value = addr;
                  }) (builtins.filter isIp4Addr selfClientConf.allowedIPs)
                )
              );
          ipv6 =
            lib.mergeAttrs
              {
                method = "manual";
                dns = builtins.head (builtins.filter isIp6Addr data.wg_vpn.network.dns);
                dns-search = data.wg_vpn.network.searchDomain;
              }
              (
                lib.attrsets.listToAttrs (
                  lib.imap1 (i: addr: {
                    name = "address${builtins.toString i}";
                    value = addr;
                  }) (builtins.filter isIp6Addr selfClientConf.allowedIPs)
                )
              );
        }
        (
          lib.attrsets.listToAttrs (
            builtins.map (iServer: {
              name = "wireguard-peer.${iServer.pubKey}";
              value = {
                endpoint = iServer.endpoint;
                allowed-ips = (builtins.concatStringsSep ";" iServer.allowedIPs) + ";";
              };
            }) (builtins.attrValues data.wg_vpn.knownServers)
          )
        );

    ensureProfiles.secrets.entries = [
      {
        matchId = "wgVpn";
        matchType = "wireguard";
        matchSetting = "wireguard";
        key = "private-key";
        file = "/run/secrets/wg_vpn/privkey";
      }
    ];
  };

  # wg-quick based implementation (the fallback)
  networking.wg-quick.interfaces.wgVpn = lib.mkIf (implMode == "wg-quick") {
    privateKeyFile = "/run/secrets/wg_vpn/privkey";
    address = selfClientConf.allowedIPs;
    dns = data.wg_vpn.network.dns;
    peers = (
      builtins.map (iServer: {
        publicKey = iServer.pubKey;
        endpoint = iServer.endpoint;
        allowedIPs = iServer.allowedIPs;
        persistentKeepalive = (lib.mkIf selfClientConf.keepalive 25);
      }) (builtins.attrValues data.wg_vpn.knownServers)
    );
  };

  sops.secrets = {
    "wg_vpn/privkey" = {
      owner = "systemd-network";
    };
  };
}
