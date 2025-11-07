# NixOS ip based allowed ports

[![FlakeHub](https://img.shields.io/endpoint?url=https://flakehub.com/f/Oak-Digital/nixos-ip-whitelist-firewall/badge)](https://flakehub.com/flake/Oak-Digital/nixos-ip-whitelist-firewall)

This NixOS module lets you open ports in your firewall that is only accepted by certain ips.

Let's say you have a postgresql database that you want to access from another server, then instead of opening the port to the entire world, you can just open the port to specific ips.

```nix
{
  networking.firewall.ipBasedAllowedTCPPorts = [
    {
      port = 5432;
      ips = [
        ipOffice
        ipHome
      ];
    }
  ];
}
```

## Usage and installation

To use this module, add the flake to your flake.

```nix
# flake.nix
{
  inputs = {
    ip-whitelist.url = "github:Oak-Digital/nixos-ip-whitelist-firewall";
  };
  # ...
}
```

Then import the module in your configuration.

```nix
{ inputs, ... }:

{
  imports = [
    inputs.ip-whitelist.nixosModules.default
  ];
  #...
}
```

And now you can configure the ports that should be ip whitelisted.

```nix
let
  ipOffice = "x.x.x.x";
  ipHome = "y.y.y.y";
  ipDatacenter = "z.z.z.z/24";
  ipv6Office = "2001:db8::1";
  ipv6Home = "2001:db8::2";
in
{
  networking.firewall.ipBasedAllowedTCPPorts = [
    {
      port = 5432;
      ips = [
        ipOffice
        ipHome
        ipDatacenter
        ipv6Office
        ipv6Home
      ];
    }
  ];
}
```

## IPv6 Support

The module automatically detects whether an IP address is IPv4 or IPv6 and uses the appropriate firewall command (`iptables` for IPv4, `ip6tables` for IPv6). You can mix both IPv4 and IPv6 addresses in the same configuration:

```nix
{
  networking.firewall.ipBasedAllowedTCPPorts = [
    {
      port = 443;
      ips = [
        "192.0.2.1"                    # IPv4 address
        "198.51.100.0/24"              # IPv4 CIDR range
        "2001:db8::1"                  # IPv6 address
        "2001:db8:abcd::/48"           # IPv6 CIDR range
      ];
    }
  ];
}
```
