# Mobile VPN Gateway

## Requirements

- A Debian cloud server or Docker image (e.g. Vultr)

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
git clone https://github.com/swizx/unchain
cd unchain/
chmod +x install-server.sh
./install-server.sh
# Set a password and go
```

2. Install Client with git (AR300M Mini Router):

```
# Before you start make sure the router is connected to Internet, either via WAN port or Wi-Fi (Repeater mode)
# Connect any device and open secure shell: ssh root@192.168.8.1
opkg update
opkg install git-http
git clone https://github.com/swizx/unchain
cd unchain/
chmod +x install-client.sh
./install-client.sh
# Enter server IP, password and go
```

## Use

This box is portable and built for traveling, public Wi-Fi environments, and working remotely. It's super easy to use:

- You can use WAN port or connect wireless to public hotspots (see 'Repeater mode'), it will be auto detected during startup
- Use switch button to turn VPN on/off (Left = ON / Right = OFF), keep the button left and VPN always starts automatically
- Simply connect your devices via LAN or WLAN

Keep in mind that there is no kill switch since this is not meant to be a privacy protector. Your traffic will be highly encrypted but the actual purpose of this VPN is to penetrate firewalls and allow you to use blocked protocols like IPsec in weird locations. Be safe and happy travels! :)

## Troubleshooting

- Sometimes it helps to turn off 'DNS Rebinding Attack Protection' if you encounter problems with obtaining the captive portal from public hotspots
- DNS queries will be sent to the hotspot gateway, to route them through VPN as well set 'Manual DNS Server Settings' to 192.168.30.1

## Info

Protocol: HTTP over TLS (SoftEther VPN)

Server port: TCP 443
