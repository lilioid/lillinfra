# IPAM for my home network

## VLANs

- **Management**: `2` (switch ports eth21 - eth24)
- **Freifunk**: `100` (switch ports eth3, eth4)
- **Smart Home**: `101` (switch ports eth5 - eth8)
- **Servers**: `102` (switch ports eth9 - eth12)
- **Main Network**: `103` (switch ports eth13 - eth16)
- **WAN**: `255` (switch ports eth1, eth2)

See [Switch Config Reference](https://help.mikrotik.com/docs/spaces/SWOS/pages/76415036/CRS3xx+and+CSS326-24G-2S+series+Manual#CRS3xxandCSS32624G2S+seriesManual-VLANandVLANs).
Switch ports eth17 - eth20 are used for generic tagged transport just like the sfp ports.

## IP Addresses

- **Management Network**:
  - Router: `192.168.2.1`
  - Cloud Smart Switch: `192.168.2.2`

- **WAN Network**:
  - Router: `192.168.255.2`
  - Fritz!Box Modem: `192.168.255.1`  

