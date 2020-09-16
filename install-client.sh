#!/bin/sh
# This install script will build SoftEther VPN as init.d service on this system, flush and recreate routing table, restard udhcpd, add iptables forwarding rule for virtual vpn interface, and change switch button configuration
# VPN starts/stops according to the switch button position (Left = ON / Right = OFF)
# Run this on gl.inet AR300M Firmware 3.104 with OpenWrt 18.06.1 or similar
# 16-Sep-2020
# Author: @swizx

# Generic variables
PORT=443
USERNM=u2ch412_default
HUB=vhub
ACCOUNT=vpn_0
#MIN_COMPLEXITY# DNS and LED settings have been disabled
#MIN_COMPLEXITY#DNS1=1.1.1.1
#MIN_COMPLEXITY#DNS2=8.8.8.8

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
cat > /etc/init.d/sevpn << EOF
#!/bin/sh /etc/rc.common
START=99
STOP=15
### Server IP
SERVER=$SERVER
### Custom DNS (Let’s avoid DNS leaks)
#MIN_COMPLEXITY# Automatic DNS config has been removed. Please change DNS server manually using the web interface. Add DNS server '192.168.30.1' to avoid DNS leaks.
#MIN_COMPLEXITY#DNS1=$DNS1
#MIN_COMPLEXITY#DNS2=$DNS2
### Name of Account (Default: vpn_0)
ACCOUNT=$ACCOUNT
UPTIME=\$(awk '{print \$1}' /proc/uptime)
UPTIME=\${UPTIME%.*}
function ready() {
	WAIT=79
	if [ \$UPTIME -ge \$WAIT ]; then
		\$1
	else
 		SLEEP=\$((\$WAIT - \$UPTIME))
		sleep \$SLEEP
		\$1
	fi
}
function fetchip() {
	IP4=\$(curl -s ifconfig.co -4)
	if [ \$? -ne 0 ]; then
		IP4=\$(curl -s checkip.amazonaws.com)
		if [ \$? -ne 0 ]; then
			printf '%s\n' "Couldn't fetch IP address. Something went wrong. The router may not be connected to the Internet."
		fi
	fi
	printf '%s\n' "Connection up. Your new IP address is: \$IP4"
}
start() {
	LOCK=/var/lock/sevpn.lock
	if [ -f "\$LOCK" ]; then
		exit 0
	fi
	touch \$LOCK
	function proceed() {
		DNIC=\$(/sbin/ip route | awk '/default/ { print \$5 }')
		DEFAULT=\$(/sbin/ip route | awk '/default/ { print \$3; exit }')
#MIN_COMPLEXITY#		LEDVPN=\$(/bin/ls /sys/class/leds/ | awk '/:wan/ || /:lan/ { print \$0 }')
#MIN_COMPLEXITY#		echo netdev> /sys/class/leds/\$LEDVPN/trigger
#MIN_COMPLEXITY#		echo vpn_0> /sys/class/leds/\$LEDVPN/device_name
#MIN_COMPLEXITY#		echo 'link tx rx'> /sys/class/leds/\$LEDVPN/mode
		echo \$DNIC > "/tmp/sevpn-dnic"
		ip r flush table main
		route add -net 192.168.8.0 netmask 255.255.255.0 dev br-lan
		udhcpc -i \$DNIC -q
#MIN_COMPLEXITY#		uci set dhcp.@dnsmasq[0].server=\$DNS1
#MIN_COMPLEXITY#		uci add_list dhcp.@dnsmasq[0].server=\$DNS2
#MIN_COMPLEXITY#		uci set dhcp.@dnsmasq[0].noresolv='1'
#MIN_COMPLEXITY#		uci set glconfig.general.auto_dns='0'
#MIN_COMPLEXITY#		uci set glconfig.general.manual_dns='1'
#MIN_COMPLEXITY#		uci commit dhcp
#MIN_COMPLEXITY#		uci commit glconfig.general
#MIN_COMPLEXITY#		/etc/init.d/dnsmasq restart
		ip r a \$SERVER via \$DEFAULT
		udhcpc -i vpn_0 -q
		iptables -A forwarding_rule -o vpn_0 -j ACCEPT
		fetchip
		rm \$LOCK
		SWITCH_LEFT=\$(grep -o "left.*hi" /sys/kernel/debug/gpio)
		if [ -n "\$SWITCH_LEFT" ]; then
			exit 0
		else
			sleep 1
			/etc/init.d/sevpn stop
		fi
	}
	function connect() {
		vpncmd localhost /CLIENT /CMD AccountConnect \$ACCOUNT
		STATUS=\$(vpncmd localhost /CLIENT /CMD AccountStatusGet \$ACCOUNT | sed -n -e 's/^.*Session Status                            |//p')
		if [ "\$STATUS" = "Connection Completed (Session Established)" ]; then
			proceed
		else
			sleep 1
			STATUS=\$(vpncmd localhost /CLIENT /CMD AccountStatusGet \$ACCOUNT | sed -n -e 's/^.*Session Status                            |//p')
			if [ "\$STATUS" = "Connection Completed (Session Established)" ]; then
				proceed
			else
				sleep 7
				STATUS=\$(vpncmd localhost /CLIENT /CMD AccountStatusGet \$ACCOUNT | sed -n -e 's/^.*Session Status                            |//p')
				if [ "\$STATUS" = "Connection Completed (Session Established)" ]; then
					proceed
				else
						vpncmd localhost /CLIENT /CMD AccountDisconnect vpn_0
						echo "\$SERVER:$PORT:$USERNM-$HUB-\$ACCOUNT: Path or Host down. Retrying..."
						sleep 2
						connect
				fi
			fi
		fi
	}
	function check() {
		STATUS=\$(vpncmd localhost /CLIENT /CMD AccountStatusGet \$ACCOUNT | sed -n -e 's/^.*Session Status                            |//p')
		if [ "\$STATUS" = "" ]; then
			connect
		else
			/etc/init.d/sevpn restart
		fi
	}
	SWITCH_LEFT=\$(grep -o "left.*hi" /sys/kernel/debug/gpio)
	if [ -n "\$SWITCH_LEFT" ]; then
		ready check
	else
		echo 'Side switch is currently turned right.'
		echo 'Use side switch to start/stop VPN. (Left = ON / Right = OFF)'
		rm \$LOCK
		exit 0
	fi
}
stop() {
	LOCK=/var/lock/sevpn.lock
	if [ -f "\$LOCK" ]; then
		exit 0
	fi
	touch \$LOCK
	function stop() {
		if [ -f /tmp/sevpn-dnic ]; then
			DNIC=\$(cat /tmp/sevpn-dnic)
		fi
#MIN_COMPLEXITY#		LEDVPN=\$(/bin/ls /sys/class/leds/ | awk '/:wan/ || /:lan/ { print \$0 }')
		vpncmd localhost /CLIENT /CMD AccountDisconnect vpn_0
#MIN_COMPLEXITY#		echo 'none'> /sys/class/leds/\$LEDVPN/mode
#MIN_COMPLEXITY#		uci delete dhcp.@dnsmasq[0].server
#MIN_COMPLEXITY#		uci delete dhcp.@dnsmasq[0].noresolv
#MIN_COMPLEXITY#		uci set glconfig.general.manual_dns='0'
#MIN_COMPLEXITY#		uci set glconfig.general.auto_dns='1'
#MIN_COMPLEXITY#		uci commit dhcp
#MIN_COMPLEXITY#		uci commit glconfig.general
#MIN_COMPLEXITY#		/etc/init.d/dnsmasq restart
		ip r flush table main
		route add -net 192.168.8.0 netmask 255.255.255.0 dev br-lan
		if [ -f /tmp/sevpn-dnic ]; then
			udhcpc -i \$DNIC -q
		else
			udhcpc
		fi
		fetchip
		rm \$LOCK
		SWITCH_LEFT=\$(grep -o "left.*hi" /sys/kernel/debug/gpio)
		if [ -n "\$SWITCH_LEFT" ]; then
			sleep 1
			/etc/init.d/sevpn start
		else
			exit 0
		fi
	}
	ready stop
}
EOF
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
