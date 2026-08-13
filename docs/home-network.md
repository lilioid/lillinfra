# Home Network

## VLANs

- **2**: MGMT
- **255**: WAN
- **100**: Freifunk-Clients
- **101**: Smart-Home
- **102**: Servers
- **103**: Home-Net

### Router VLANs

- Every port accepts every defined VLAN as tagged
- Last Ethernet port is untagged MGMT

### raspi5

- Accepts VLANs *Smart-Home*, *Servers*, *MGMT* all tagged on it's ethernet port

### EX2300C

- ge-0/0/0:  Access WAN (uplink to FritzBox)
- ge-0/0/1:  Trunk to banana pi
- ge-0/0/2:  Access WAN (Freifunk)
- ge-0/0/3:  Trunk to Raspberry PI
- ge-0/0/4:  Trunk to AP
- ge-0/0/*:  Access Ports for Home-Net
- ge-0/0/11: Access MGMT

### WiFi AP

- Uses MGMT as native VLAN
- All other networks from SSIDs as tagged


## IP Addresses

- **Management Network**:
  - Router (banana pi): `192.168.2.1`
  - Switch (ex2300c): `192.168.2.2`

- **WAN Network**:
  - Fritz!Box Modem: `192.168.255.1`  
  - Router: `192.168.255.2`
  - Freifunk Router: Dynamic Address from DHCP pool

