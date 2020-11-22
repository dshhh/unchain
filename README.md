# 

This install script allows you to pass through firewalls and use potentially blocked protocols like IPsec in remote locations.

## Requirements

- 1x A Debian cloud server or Docker image (e.g. Vultr, AWS, etc)

- 1x GL iNet GL-AR300M Mini Router

## Install

1. Install Server (Debian 10 or 9):

```
chmod +x install-server.sh
./install-server.sh
# Set a password
```

2. Install Client (AR300M Mini Router):

```
# Make sure internet is connected
opkg install git-http
chmod +x install-client.sh
./install-client.sh
# Enter server IP and password
```

## Use

This box is portable and built for traveling, public Wi-Fi environments, and remote work. It's easy to use:

- Use the switch next to the reset button to switch VPN on or off
- Simply connect any device to the box via LAN port or Wi-Fi network and enjoy your unrestricted network
- You can connect wirelessly to public hotspots (see 'Repeater mode')

You can permanently disable the process with

```
/etc/init.d/sevpn disable
```

or re-enable with

```
/etc/init.d/sevpn enable
```

## Troubleshooting

- Turn off 'DNS Rebinding Attack Protection' if you encounter problems with obtaining the captive portal from public hotspots

## Info

Protocol: TLS (SoftEther VPN)

Server port: TCP 443

Encryption: AES 128 or AES 256

Hash: SHA-1
