# Home Network

## VLANs

- **2**: MGMT
  - Untagged on last ethernet port of every device
- **255**: WAN
- **100**: Freifunk-Clients
- **101**: Smart-Home
- **102**: Servers
- **103**: Main User Net

## Router VLANs

- Every port accepts every defined VLAN as tagged
- Last Ethernet port is untagged MGMT

## raspi5

- Accepts VLANs *Smart-Home*, *Servers*, *MGMT* all tagged on it's ethernet port

