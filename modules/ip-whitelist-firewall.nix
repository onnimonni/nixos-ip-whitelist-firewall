{ lib, config, ... }:

let
  inherit (lib)
    types
    mkOption;

  portWithIps = with types; submodule {
    options = {
      port = mkOption {
        type = int;
        description = ''
          The TCP port that is allowed to be accessed from the outside.
        '';
      };

      ips = mkOption {
        type = with types; listOf str;
        default = [ ];
        description = ''
          The IP addresses that are allowed to access the port.
          You can also use CIDR notation to specify a range of IP addresses.
        '';
      };
    };
  };
in
{
  options = {
    networking.firewall.ipBasedAllowedTCPPorts = mkOption {
      default = [ ];
      type = with types; listOf portWithIps;
      description = ''
        List of TCP ports that are allowed to be accessed by specified ips.
      '';
    };

    networking.firewall.ipBasedAllowedUDPPorts = mkOption {
      default = [ ];
      type = with types; listOf portWithIps;
      description = ''
        List of UDP ports that are allowed to be accessed by specified ips.
      '';
    };
  };

  config =
    let
      # Helper function to check if an IP is IPv6
      isIPv6 = ip: lib.strings.hasInfix ":" ip;

      # Filter IPv4 and IPv6 addresses
      filterIPv4 = ips: builtins.filter (ip: !(isIPv6 ip)) ips;
      filterIPv6 = ips: builtins.filter isIPv6 ips;

      # Create commands for IPv4 (iptables)
      createIPv4Command = proto: port: ip: ''
        iptables -A nixos-fw -p ${proto} --dport ${toString port} -s ${ip} -j nixos-fw-accept
      '';

      # Create commands for IPv6 (ip6tables)
      createIPv6Command = proto: port: ip: ''
        ip6tables -A nixos-fw -p ${proto} --dport ${toString port} -s ${ip} -j nixos-fw-accept
      '';

      # Remove commands for IPv4
      removeIPv4Command = proto: port: ip: ''
        iptables -D nixos-fw -p ${proto} --dport ${toString port} -s ${ip} -j nixos-fw-accept || true
      '';

      # Remove commands for IPv6
      removeIPv6Command = proto: port: ip: ''
        ip6tables -D nixos-fw -p ${proto} --dport ${toString port} -s ${ip} -j nixos-fw-accept || true
      '';
    in
    {
      # IPv4 firewall rules
      networking.firewall.extraCommands = ''
        # Allow access to the specified TCP ports from the specified IPv4 addresses.
        ${lib.concatMapStringsSep "\n" (portWithIps: ''
          ${lib.concatMapStringsSep "\n" (ip: ''
            ${createIPv4Command "tcp" portWithIps.port ip}
          '') (filterIPv4 portWithIps.ips)}
        '') config.networking.firewall.ipBasedAllowedTCPPorts}

        # Allow access to the specified UDP ports from the specified IPv4 addresses.
        ${lib.concatMapStringsSep "\n" (portWithIps: ''
          ${lib.concatMapStringsSep "\n" (ip: ''
            ${createIPv4Command "udp" portWithIps.port ip}
          '') (filterIPv4 portWithIps.ips)}
        '') config.networking.firewall.ipBasedAllowedUDPPorts}
      '';

      networking.firewall.extraStopCommands = ''
        # Drop ip based allowed tcp ports rules for IPv4
        ${lib.concatMapStringsSep "\n" (portWithIps: ''
          ${lib.concatMapStringsSep "\n" (ip: ''
            ${removeIPv4Command "tcp" portWithIps.port ip}
          '') (filterIPv4 portWithIps.ips)}
        '') config.networking.firewall.ipBasedAllowedTCPPorts}

        # Drop ip based allowed udp ports rules for IPv4
        ${lib.concatMapStringsSep "\n" (portWithIps: ''
          ${lib.concatMapStringsSep "\n" (ip: ''
            ${removeIPv4Command "udp" portWithIps.port ip}
          '') (filterIPv4 portWithIps.ips)}
        '') config.networking.firewall.ipBasedAllowedUDPPorts}
      '';

      # IPv6 firewall rules
      networking.firewall.extraIPv6Commands = ''
        # Allow access to the specified TCP ports from the specified IPv6 addresses.
        ${lib.concatMapStringsSep "\n" (portWithIps: ''
          ${lib.concatMapStringsSep "\n" (ip: ''
            ${createIPv6Command "tcp" portWithIps.port ip}
          '') (filterIPv6 portWithIps.ips)}
        '') config.networking.firewall.ipBasedAllowedTCPPorts}

        # Allow access to the specified UDP ports from the specified IPv6 addresses.
        ${lib.concatMapStringsSep "\n" (portWithIps: ''
          ${lib.concatMapStringsSep "\n" (ip: ''
            ${createIPv6Command "udp" portWithIps.port ip}
          '') (filterIPv6 portWithIps.ips)}
        '') config.networking.firewall.ipBasedAllowedUDPPorts}
      '';

      networking.firewall.extraIPv6StopCommands = ''
        # Drop ip based allowed tcp ports rules for IPv6
        ${lib.concatMapStringsSep "\n" (portWithIps: ''
          ${lib.concatMapStringsSep "\n" (ip: ''
            ${removeIPv6Command "tcp" portWithIps.port ip}
          '') (filterIPv6 portWithIps.ips)}
        '') config.networking.firewall.ipBasedAllowedTCPPorts}

        # Drop ip based allowed udp ports rules for IPv6
        ${lib.concatMapStringsSep "\n" (portWithIps: ''
          ${lib.concatMapStringsSep "\n" (ip: ''
            ${removeIPv6Command "udp" portWithIps.port ip}
          '') (filterIPv6 portWithIps.ips)}
        '') config.networking.firewall.ipBasedAllowedUDPPorts}
      '';
    };
}
