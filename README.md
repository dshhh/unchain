# unchain: Mobile VPN Gateway

## Requirements

- A Debian cloud server or Docker image (e.g. Vultr, AWS, etc)

- GL iNet GL-AR300M Mini Router

## Install

1. Install Server (Debian 10 or 9):
```
./install-server.sh
```
2. Install Client (AR300M Mini Router):
```
./install-client.sh
```

## Install with git (detailed instructions)

1. Install Server with git (Debian 10 or 9):

```
apt update
apt install git -y
git clone https://github.com/bhadid/unchain
cd unchain/
chmod +x install-server.sh
./install-server.sh
# Set a password and go
```

2. Install Client with git (AR300M Mini Router):

```
# Before you start make sure the router is connected to the internet, either via WAN port or Wi-Fi (Repeater mode)
# Open secure shell: ssh root@192.168.8.1
opkg update
opkg install git-http
git clone https://github.com/bhadid/unchain
cd unchain/
chmod +x install-client.sh
./install-client.sh
# Enter server IP, password and go
```

## Use

This box is portable and built for traveling, public Wi-Fi environments, and working remotely. It's super easy to use:

- You can use the WAN port or connect wirelessly to public hotspots (see 'Repeater mode')
- Use the switch button to disconnect from VPN (Left = ON / Right = OFF) or keep the button left to make the VPN start automatically at all times
- Simply connect any devices to the box via LAN port or Wi-Fi network and enjoy your unrestricted network

You can permanently disable the VPN with

```
/etc/init.d/sevpn disable
```

or re-enable with

```
/etc/init.d/sevpn enable
```

Note that while VPN traffic is highly encrypted (AES 128) and hashed (SHA-1) there will be no kill switch since this is not meant to be a privacy protector. The purpose of this VPN is to penetrate firewalls and allowing the user to use blocked protocols like IPsec in weird locations. Be safe and happy travels!

## Troubleshooting

- Sometimes it helps to turn off 'DNS Rebinding Attack Protection' if you encounter problems with obtaining the captive portal from public hotspots.
- DNS queries will be sent to the default gateway. That means they are not routed trough the VPN. This is the best fit for most use cases but could cause a DNS leak. To encrypt your DNS queries and route them through the VPN as well use the web interface and set 'Manual DNS Server Settings' to '192.168.30.1'. This will make the VPN server your only source for DNS.

## Info

Protocol: HTTP over TLS (SoftEther VPN)

Server port: TCP 443
