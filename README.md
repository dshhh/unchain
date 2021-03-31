# unchain

SoftEther VPN installer for Debian and a GL-AR300M Mini Router.

## Requirements

- 1x Debian _buster_ (Debian 10) or _stretch_ (Debian 9) Cloud-hosted or elsewhere

- 1x GL-AR300M Mini Router (factory state running GL default OS on OpenWrt)

## Install

1. Install Server (Debian):

```
./server.sh
# Set a password
```

2. Install Client (OpenWrt, GL-AR300M):

```
opkg install git-http
./client.sh
# Enter server IP and password
```

## Use

* Portable, built for travel, public Wi-Fi, and remote work
* Easy to use:
  * Turn on/off with the switch button
  * Connect any type of device to the Wi-Fi from the box (or Ethernet)
  * Connect to wireless networks through the Web UI (see 'Repeater mode') or use Ethernet WAN port

You can permanently disable with

```
/etc/init.d/sevpn disable
```

Or re-enable with

```
/etc/init.d/sevpn enable
```

## Troubleshooting

- Turn off 'DNS Rebinding Attack Protection' in Web UI if you encounter problems with receiving the captive portal from public hotspots

## Protocol Info

SoftEther VPN aims for bypassing network filters and firewalls by finding any encapsulating method that works, including HTTPS (TLS 1.2) and SSH encapsulation.

Server port statically set to TCP 443
