# unchain

SoftEther VPN installer for Debian and a GL-AR300M Mini Router running OpenWrt

## Requirements

- 1x Debian _buster_ (Debian 10) or _stretch_ (Debian 9) Cloud-hosted or elsewhere

- 1x GL-AR300M Mini Router (factory state, running the default OS)

## Install

1. Install Server (Debian) (run with sudo):

```
apt-get install sudo build-essential libreadline-dev libssl-dev libncurses-dev zlib1g-dev git cmake -y
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
  * Turn on/off with the switch button (Left = ON / Right = OFF)
  * Connect any type of device to the Wi-Fi from the box or use Ethernet LAN port
  * Connect to wireless networks through the Web UI (see 'Repeater mode') or use Ethernet WAN port
  * LAN LED (green mid) displays VPN traffic

You can permanently disable with

```
/etc/init.d/sevpn disable
```

Or re-enable with

```
/etc/init.d/sevpn enable
```

## Troubleshooting

Turn off 'DNS Rebinding Attack Protection' in Web UI if you encounter problems with receiving the captive portal from public hotspots.

For any other issues see the logs with

```
less -f /var/log/sevpn.log
```

## Protocol Info

SoftEther VPN aims for bypassing network filters and firewalls by finding any encapsulating method that works, including HTTPS (TLS 1.2) and SSH encapsulation.

Server port statically set to TCP 443. If you want to change the port, change it in both scripts prior executing them.
