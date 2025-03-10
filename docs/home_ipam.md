# IPAM for my home network

## VLANs

- **Management**: `2` 
    - switch ports eth23 - eth24
    - router access port lan1 (for unifi AP) lan3 (the right-most one)
    - router trunk port all other
- **Freifunk**: `100`
    - switch ports eth3, eth4
    - router trunk sfp1, sfp2, lan0, lan1, lan2
- **Smart Home**: `101`
     - switch ports eth5 - eth8
     - router trunk sfp1, sfp2, lan0, lan1, lan2
- **Servers**: `102` 
     - switch ports eth9 - eth12
     - router trunk sfp1, sfp2, lan0, lan1, lan2
- **Main Network**: `103` 
     - switch ports eth13 - eth16
     - router trunk sfp1, sfp2, lan0, lan1, lan2
- **WAN**: `255`
     - switch ports eth1, eth2
     - router trunk sfp1, sfp2, lan0, lan1, lan2

See [Switch Config Reference](https://help.mikrotik.com/docs/spaces/SWOS/pages/76415036/CRS3xx+and+CSS326-24G-2S+series+Manual#CRS3xxandCSS32624G2S+seriesManual-VLANandVLANs).
Switch ports eth17 - eth22 are used for generic tagged transport just like the sfp ports.

## IP Addresses

- **Management Network**:
  - Router: `192.168.2.1`
  - Cloud Smart Switch: `192.168.2.2`

- **WAN Network**:
  - Router: `192.168.255.2`
  - Fritz!Box Modem: `192.168.255.1`  

