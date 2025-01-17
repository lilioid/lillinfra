# Wireguard VPN

I'm operating a wireguard VPN server at `vpn.lly.sh`.
The serve forwards IP packets between other connected peers and serves as an entry-point into the VPN network.

It uses the IP-Space `10.20.30.0/24` as well as `fc10:20:30::/64`.

## Rendering a config file

The script `,show-wg-conf` (available via package [show-wg-conf](../nix/packages/show-wg-conf/)) can print out the configuration of an arbitrary VPN participant, provided that key material is available to sops (in `.config/sops/age/keys.txt`).

```text
> ,show-wg-conf --text lillysLaptop
[Interface]
PrivateKey = …
DNS=10.20.30.1,fc10:20:30::1
Address=10.20.30.103/32
Address=fc10:20:30::103/128

[Peer]
# proxy.srv.home.intern
PublicKey=GTWotNqG3way+5NacVVs9bDwbLXplo/afSwZzU2XzkU=
AllowedIPs=10.20.30.3/32,fc10:20:30::3/128
Endpoint=home.lly.sh:51820
PersistentKeepalive=0

[Peer]
# vpn-server
PublicKey=SRVfDEjWZCEcxynQoK1iibpzVeDN61ghTEQPps3pmSY=
AllowedIPs=10.20.30.0/24,fc10:20:30::0/64
Endpoint=vpn.lly.sh:51820
PersistentKeepalive=0
```

