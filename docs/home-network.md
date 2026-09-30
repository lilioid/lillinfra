# Home Network

## VLANs

- **2**: MGMT
- **255**: WAN
- **100**: Freifunk-Clients
- **101**: Smart-Home
- **102**: Servers
- **103**: Home-Net

<!-- ### Router VLANs -->

<!-- - Every port accepts every defined VLAN as tagged -->
<!-- - Last Ethernet port is untagged MGMT -->

### raspi5

- Accepts VLANs *Smart-Home*, *Servers*, *MGMT* all tagged on it's ethernet port

### EX2300C

> **currently not in use**

- ge-0/0/0:  Access WAN (uplink to FritzBox)
- ge-0/0/1:  Trunk to banana pi
- ge-0/0/2:  Access WAN (Freifunk)
- ge-0/0/3:  Trunk to Raspberry PI
- ge-0/0/4:  Trunk to AP
- ge-0/0/*:  Access Ports for Home-Net
- ge-0/0/11: Access MGMT

### SRX300

- ge-0/0/0: Access WAN (uplink to FritzBox)
- ge-0/0/1: Trunk to AP (with external POE injector)
- ge-0/0/2: Trunk to raspi5
- ge-0/0/3: Access Home-Net (printer)
- ge-0/0/4: Access Home-Net (lillysWorkstation)
- ge-0/0/5: Access MGMT
- ge-0/0/6 (SFP): *disabled*
- ge-0/0/7 (SFP): *disabled*

### WiFi AP

- Uses MGMT as native VLAN
- All other networks from SSIDs as tagged

## IP Addresses

- **Management Network**:
  - Pool: `192.168.2.100 - 192.168.2.254`
  - Router (srx300): `192.168.2.1`
  - Switch (ex2300c): `192.168.2.2`

- **SmartHome**:
  - Pool: `192.168.101.100 - 192.168.101.254`
  - Static Leases & DNS Cache Entries:
  
    | Name                          | Static Lease     |
    | ----------------------------- | ---------------- |
    | dusty.smart.home.internal     | `192.168.101.10` |
    | starlight.smart.home.internal | `192.168.101.11` |
    | airgradient-livingroom.smart.home.internal | `192.168.101.12` |

- **Servers**:
  - Pool: `192.168.102.100 - 192.168.102.254`
  - Static Leases & DNS Cache Entries:
  
    | Name                         | Static Lease     |
    | ---------------------------- | ---------------- |
    | raspi5.servers.home.internal | `192.168.102.10` |
    | proxy.servers.home.internal  | `192.168.102.11` |
    | priv.servers.home.internal   | `192.168.102.12` |

- **Home-Net**:
  - Pool: `192.168.103.2 - 192.168.103.254`

- **WAN Network**:
  - Fritz!Box Modem: `192.168.255.1` 
  - Router: `192.168.255.2`
  - Freifunk Router: Dynamic Address from DHCP pool

