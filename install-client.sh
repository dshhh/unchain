#!/bin/sh
# This install script will build SoftEther VPN as init.d service on this system, flush and recreate routing table, restard udhcpd, add iptables forwarding rule for virtual vpn interface, and change switch button configuration
# VPN starts/stops according to the switch button position (Left = ON / Right = OFF)
# Run this on gl.inet AR300M Firmware 3.104 with OpenWrt 18.06.1 or similar
# 25-Sep-2020
# Author: @swizx

# Generic variables
PORT=443
USERNM=u2ch412_default
HUB=vhub
ACCOUNT=vpn_0

# User variables
read -p "Enter VPN server address: " SERVER
read -p "Enter VPN user password: " PASSWD

# Start
echo "That's it. Starting setup..."

# Download packages
opkg install softethervpn
if [ $? -ne 0 ]; then
	echo "Failed to install SoftEther VPN. Run 'opkg update' and try again."
	exit 1
fi

# Stop and disable redundant services
/etc/init.d/softethervpnbridge disable
/etc/init.d/softethervpnserver disable
/etc/init.d/softethervpnbridge stop
/etc/init.d/softethervpnserver stop

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
cat > /usr/bin/switchaction << EOF
#!/bin/sh
set_function(){
	# Using lock, avoid restart repeatedly
	LOCK=/var/lock/switch.lock
	if [ -f "\$LOCK" ];then
		exit 0
	fi
	touch \$LOCK
	switch_disabled="0"
	switch_enabled=\$(uci get glconfig.switch_button.enable)
	switch_func=\$(uci get glconfig.switch_button.function)
	switch_left=\$(grep -o "left.*hi" /sys/kernel/debug/gpio)
	if [ "\$switch_disabled" = "1" ] || [ "\$switch_enabled" != "1" ]; then
		rm \$LOCK
		exit 0
	fi
	#if switch is on left
	if [ -n "\$switch_left" ]; then
		case "\$switch_func" in
			"sevpn")
				/etc/init.d/sevpn start
			;;
			"*")
			;;
		esac
	else
		case "\$switch_func" in
			"sevpn")
				/etc/init.d/sevpn stop
			;;
			"*")
			;;
		esac
	fi
	rm \$LOCK
}
set_function
EOF
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
	read -t 15 -r -p "Side switch is currently turned left. Establish connection now? [y/N] " response
	case "$response" in
		[yY][eE][sS]|[yY])
			echo Starting VPN connection…
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
	sleep 1
	echo Side switch is currently turned right. VPN remains disconnected.
	exit 0
fi
