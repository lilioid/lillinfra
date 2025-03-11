{ ... }:
{
  services.frr = {
    bgpd.enable = true;
    bgpd.extraOptions = [
      "--listenon=2a10:9906:1002:0:125::126"
      "--listenon=::1"
      "--listenon=127.0.0.1"
    ];
    config = ''
      frr version 10.1
      frr defaults traditional

      hostname rt-hosting.srv.ftsell.de

      ! BGP Router config
      router bgp 214493
        no bgp default ipv4-unicast
        bgp default ipv6-unicast
        bgp ebgp-requires-policy
        no bgp network import-check

        neighbor myroot peer-group
        neighbor myroot remote-as 39409
        neighbor myroot capability dynamic
        neighbor 2a10:9906:1002::2 peer-group myroot

        address-family ipv6 unicast
          network 2a10:9902:111::/48
          # redistribute kernel
          # aggregate-address 2a10:9902:111::/48 summary-only
          neighbor myroot prefix-list pl-allowed-export out
          neighbor myroot prefix-list pl-allowed-import in
        exit-address-family

      ip prefix-list pl-allowed-import seq 5 permit ::/0
      ip prefix-list pl-allowed-export seq 5 permit 2a10:9902:111::/48
    '';
  };
}
