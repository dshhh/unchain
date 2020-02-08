# Mobile VPN-Gateway

## Requirements

- Debian (Cloud) Server

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
git clone https://github.com/sk3dd/unchain
cd unchain/
chmod +x install-server.sh
./install-server.sh
#** Set a password and go **#
```

2. Install Client with git (AR300M Mini Router):

```
#** Connect router with Internet, wired (Ethernet) or wireless (Repeater mode) **#
#** ssh root@192.168.8.1 **#
opkg update
opkg install git-http
git clone https://github.com/sk3dd/unchain
cd unchain/
chmod +x install-client.sh
./install-client.sh
#** Enter server IP and password and go **#
```

## Use

- Switch button right turns VPN off, left turns it on
- LED shows VPN status and VPN traffic

## Info

Protocol: Ethernet over HTTPS (HTTP Over TLS 1.2) (SoftEther VPN)
