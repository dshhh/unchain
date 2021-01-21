# unchain

SoftEther VPN installer for Debian and OpenWrt Client on GL-AR300M

## Requirements

- 1x Debian Server (_buster_ (Debian 10) or _stretch_ (Debian 9))

- 1x GL-AR300M Mini Router

## Install

1. Install Server (Debian):

```
./install-server.sh
# Set a password
```

2. Install Client (GL-AR300M):

```
# Make sure internet is connected
opkg install git-http
./install-client.sh
# Enter server IP and the password
```

## Use

* Portable, built for travel, public Wi-Fi, and remote work
* Easy to use:
  * Turn VPN on/off with the switch button
  * Connect any type of device to the box and enjoy a unrestricted network via LAN or WLAN
  * Connect wirelessly to public hotspots (see 'Repeater mode')

You can permanently disable the process with

```
/etc/init.d/sevpn disable
```

Or re-enable with

```
/etc/init.d/sevpn enable
```

## Troubleshooting

- Turn off 'DNS Rebinding Attack Protection' if you encounter problems with obtaining the captive portal from public hotspots

## Info

Protocol: SoftEther VPN

Server port: TCP 443
