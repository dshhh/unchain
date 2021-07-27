#!/bin/sh

# Pre configured parameters
PORT=443
USERNM=unchain_default
HUB=vhub
ACCOUNT=vpn_0

# User input parameters
read -p "Enter VPN server address: " SERVER
read -p "Enter VPN user password: " PASSWD

# Start
echo "OK. Installing..."

# Download packages
opkg install softethervpn-client
if [ $? -ne 0 ]; then
	echo "Failed to install SoftEther VPN. Run 'opkg update' and try again."
	exit 1
fi

# Create VPN interface
vpncmd localhost /CLIENT /CMD NicCreate 0

# Create VPN user account
vpncmd localhost /CLIENT /CMD AccountCreate $ACCOUNT /SERVER:$SERVER:$PORT /HUB:$HUB /USERNAME:$USERNM /NICNAME:0

# Set VPN user password
vpncmd localhost /CLIENT /CMD AccountPasswordSet $ACCOUNT /PASSWORD:${PASSWD//!/\!} /TYPE:standard >/dev/null

# Create init.d service
cat ./sevpn > /etc/init.d/sevpn
sed -i "s/^SERVER=.*/SERVER=$SERVER/g" /etc/init.d/sevpn
chmod 0755 /etc/init.d/sevpn

# Enable startup script
/etc/init.d/sevpn enable

# Create switch button action script to be able to disconnect from VPN easily
mv /usr/bin/switchaction /usr/bin/switchaction.bak
cat ./switchaction > /usr/bin/switchaction
chmod 0755 /usr/bin/switchaction

# Disable initswitch as it has been integrated in init.d/sevpn service
/etc/init.d/initswitch disable

# Enable and configure switch button
uci set glconfig.switch_button=service
uci set glconfig.switch_button.enable='1'
uci set glconfig.switch_button.function='sevpn'
cat <<EOT >> /etc/rc.local
uci set glconfig.switch_button=service
uci set glconfig.switch_button.enable='1'
uci set glconfig.switch_button.function='sevpn'
EOT

# Finish, last chance to abort server call
echo VPN is ready.
sleep 1
echo 'Use side switch to start/stop VPN. (Left = ON / Right = OFF)'
SWITCH_LEFT=$(grep -o "left.*hi" /sys/kernel/debug/gpio)
if [ -n "$SWITCH_LEFT" ]; then
	read -t 15 -r -p "VPN is ready. Establish connection now? [y/N] " response
	case "$response" in
		[yY][eE][sS]|[yY])
			echo Starting VPN connection...
			/etc/init.d/sevpn start
		;;
		[nN][oO]|[nN]|$'\x1b')
			echo OK. Remaining disconnected for now.
			exit 0
		;;
		*)
			echo -e
			echo Proceeding due to a timeout...
			sleep 1
			echo Starting VPN connection...
			/etc/init.d/sevpn start
		;;
	esac
else
	read -t 15 -r -p "VPN is ready. Establish connection now? [y/N] " response
	case "$response" in
		[yY][eE][sS]|[yY])
			echo Starting VPN connection...
			/etc/init.d/sevpn start
		;;
		[nN][oO]|[nN]|$'\x1b')
			echo OK. Remaining disconnected.
			exit 0
		;;
		*)
			echo -e
			echo Proceeding due to a timeout...
			sleep 1
			echo Starting VPN connection...
			/etc/init.d/sevpn start
		;;
	esac
fi
