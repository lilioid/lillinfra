{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.custom.wg;

  # owner of the files in /run/secrets (sops-nix stuff)
  secretOwner =
    if cfg.implementation == "systemd-networkd" then
      "systemd-networkd"
    else if cfg.implementation == "network-manager" then
      "root"
    else
      "root";

  # utility function to filter an AttrSet to only include the members who have their .enable attr set to true
  filterEnabled = lib.attrsets.filterAttrs (_: i: i.enable);

  isIp4Addr = addr: !(isIp6Addr addr);
  isIp6Addr = addr: lib.strings.hasInfix ":" addr;

  getV4Addrs = addrs: lib.lists.filter isIp4Addr addrs;
  getV6Addrs = addrs: lib.lists.filter isIp6Addr addrs;

  # calculate a specially formed AttrSet with address1, address2, … keys that is used for NetworkManager ip sections
  mkNmAddrAttrset = addrs: lib.attrsets.listToAttrs
    (lib.imap1
      (i: addr: {
        name = "address${builtins.toString i}";
        value = addr;
      })
      addrs);

  # calculate a specially formed AttrSet with wireguard-peer.$pubkey being the key and that peers configuration being the value
  # used for NetworkManager configuration
  mkNmPeerAttrset = peers: lib.attrsets.listToAttrs
    (lib.lists.map
      (iPeer: {
        name = "wireguard-peer.${iPeer.pubKey}";
        value = {
          endpoint = lib.mkIf (iPeer.endpoint != null) iPeer.endpoint;
          allowed-ips = (builtins.concatStringsSep ";" iPeer.allowedIPs) + ";";
        };
      })
      (lib.attrsets.attrValues peers));
in
{

  #
  # API Declaration
  #
  options = with lib.options; {
    custom.wg = {

      implementation = mkOption {
        description = "Which downstream management tooling to render configuration for";
        type = lib.types.enum [ "systemd-networkd" "network-manager" "wg-quick" ];
        defaultText = "Depending on which tooling is enabled, 'systemd-networkd', 'network-manager' or 'wg-quick' in that priority order";
        default =
          if config.systemd.network.enable then
            "systemd-networkd"
          else if config.networking.networkmanager.enable then
            "network-manager"
          else
            "wg-quick";
      };

      profiles = mkOption {
        description = "Definition of WireGuard connection profiles";
        default = { };
        type = with lib.types; attrsOf (submodule (
          { config, ... }: {
            options = {
              enable = mkOption {
                description = "Whether to enable WireGuard profile ${config._module.args.name}";
                default = true;
                type = bool;
              };
              interface = mkOption {
                description = "Name of the WireGuard interface to generate";
                default = config._module.args.name;
                defaultText = "name of the profile";
                type = str;
              };
              address = mkOption {
                description = "IP Addresses in CIDR notation that the local interface should get";
                type = listOf str;
              };
              dns = mkOption {
                description = "DNS Server addresses to use on this interface/when this profile is active";
                type = listOf str;
                default = [ ];
              };
              peers = mkOption {
                description = "Definition of peers with which the WireGuard tunnel should be established";
                default = { };
                type = attrsOf (submodule {
                  options = {
                    enable = mkOption {
                      description = "Whether this peer should currently be enabled";
                      default = true;
                      type = bool;
                    };
                    pubKey = mkOption {
                      description = "Public WireGuard key of the peer";
                      type = str;
                    };
                    endpoint = mkOption {
                      description = "Statically assigned endpoint at which this peer is reachable";
                      type = nullOr str;
                      default = null;
                    };
                    allowedIPs = mkOption {
                      description = "WireGuard allowed-ips of this peer";
                      type = listOf str;
                    };
                  };
                });
              };
            };
          }
        ));
      };
    };
  };

  #
  # Implementation (by rendering into other NixOS options)
  #
  config = {
    environment.systemPackages = with pkgs; [
      wireguard-tools
    ];

    # systemd-networkd implementation
    systemd.network = lib.mkIf (cfg.implementation == "systemd-networkd") {
      netdevs = lib.mapAttrs
        (iProfileName: iProfile: {
          netdevConfig = {
            Name = iProfile.interface;
            Kind = "wireguard";
          };
          wireguardConfig = {
            PrivateKeyFile = config.sops.secrets."wg/${iProfileName}/privkey".path;
          };
          wireguardPeers = lib.mapAttrsToList
            (_: iPeer: {
              PublicKey = iPeer.pubKey;
              AllowedIPs = iPeer.allowedIPs;
              Endpoint = lib.mkIf (iPeer.endpoint != null) iPeer.endpoint;
            })
            (filterEnabled iProfile.peers);
        })
        (filterEnabled cfg.profiles);

      networks = lib.mapAttrs
        (iProfileName: iProfile: {
          matchConfig.Name = iProfile.interface;
          address = iProfile.address;
        })
        (filterEnabled cfg.profiles);
    };

    # NetworkManager implementation
    networking.networkmanager = lib.mkIf (cfg.implementation == "network-manager") {
      ensureProfiles.profiles = lib.mapAttrs
        (iProfileName: iProfile:
          let
            v4DnsAddrs = getV4Addrs iProfile.dns;
            v6DnsAddrs = getV6Addrs iProfile.dns;
          in
          {
            connection = {
              id = iProfileName;
              type = "wireguard";
              autoconnect = true;
              interface-name = iProfile.interface;
            };
            wireguard = {
              private-key-flags = 1;
            };
            ipv4 = {
              method = "manual";
              dns = lib.mkIf (lib.lists.length v4DnsAddrs > 0) (lib.lists.head v4DnsAddrs);
            } // (mkNmAddrAttrset (getV4Addrs iProfile.address));
            ipv6 = {
              method = "manual";
              dns = lib.mkIf (lib.lists.length v6DnsAddrs > 0) (lib.lists.head v6DnsAddrs);
            } // (mkNmAddrAttrset (getV6Addrs iProfile.address));
          } // (mkNmPeerAttrset (filterEnabled iProfile.peers)))
        (filterEnabled cfg.profiles);

      ensureProfiles.secrets.entries = lib.mapAttrsToList
        (iProfileName: iProfile: {
          matchId = iProfileName;
          matchType = "wireguard";
          matchSetting = "wireguard";
          key = "private-key";
          file = config.sops.secrets."wg/${iProfileName}/privkey".path;
        })
        (filterEnabled cfg.profiles);
    };

    # wg-quick implementation
    networking.wg-quick = lib.mkIf (cfg.implementation == "wg-quick") {
      interfaces = lib.mapAttrs
        (iProfileName: iProfile: {
          privateKeyFile = config.sops.secrets."wg/${iProfileName}/privkey".path;
          address = iProfile.address;
          dns = iProfile.dns;
          peers = lib.mapAttrsToList
            (_: iPeer: {
              publicKey = iPeer.pubKey;
              endpoint = iPeer.endpoint;
              allowedIPs = iPeer.allowedIPs;
            })
            (filterEnabled iProfile.peers);
        })
        (filterEnabled cfg.profiles);
    };

    # definition of connection secrets (used by all implementations)
    sops.secrets = lib.attrsets.mapAttrs'
      (iProfileName: iProfile: {
        name = "wg/${iProfileName}/privkey";
        value = {
          owner = secretOwner;
        };
      })
      (filterEnabled cfg.profiles);
  };
}
