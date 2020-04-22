# Mobile VPN-Gateway

## Requirements

- A Debian cloud server or Docker image

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
git clone https://github.com/da9d/unchain
cd unchain/
chmod +x install-server.sh
./install-server.sh
#** Set a password and go **
```

2. Install Client with git (AR300M Mini Router):

```
#** Connect router to Internet via WAN port or Wi-Fi (Repeater mode) **
#** ssh root@192.168.8.1 **
opkg update
opkg install git-http
git clone https://github.com/da9d/unchain
cd unchain/
chmod +x install-client.sh
./install-client.sh
#** Enter server IP, password and go **
```

## Use

This box is portable and built for traveling, public Wi-Fi environments, and working remotely. It's super easy to use:

- VPN starts automatically
- Use switch button to turn VPN on/off (Left = ON / Right = OFF)
- Both WAN port and LAN port can be used or use one or both wireless (see 'Repeater mode'), it will be auto detected
- LED shows VPN status (up) and VPN traffic (flashing)
- Reboot may be required after install

## Info

Protocol: HTTP over TLS (SoftEther VPN)
Server port: 443
