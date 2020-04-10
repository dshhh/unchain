#!/bin/sh
# This script will install SoftEther VPN, add a startup script, configure additional features and set up a connection with a pre-configured server
# Run this on gl.inet AR300M Firmware 3.024 with OpenWrt 18.06.1 or similar
# 4-Feb-2020
# github.com/sk3dd

# Set parameters
read -p "Enter VPN server address: " SERVER
read -p "Enter VPN user password: " PASSWD
USERNM=unchainVpnUser
HUB=vhub
ACCOUNT=vpn_0
DNS1=1.1.1.1
DNS2=8.8.8.8

# Download packages
opkg install softethervpn
if [ $? -ne 0 ]; then
	echo "Failed to install SoftEther VPN. Run 'opkg update' and try again."
	exit 1
fi

# Stop and disable obsolete services
/etc/init.d/softethervpnbridge disable
/etc/init.d/softethervpnserver disable
/etc/init.d/softethervpnbridge stop
/etc/init.d/softethervpnserver stop

# Configure VPN
vpncmd localhost /CLIENT /CMD NicCreate 0
vpncmd localhost /CLIENT /CMD AccountCreate $ACCOUNT /SERVER:$SERVER:443 /HUB:$HUB /USERNAME:$USERNM /NICNAME:0
vpncmd localhost /CLIENT /CMD AccountPasswordSet $ACCOUNT /PASSWORD:${PASSWD//!/\!} /TYPE:standard >/dev/null

# Create init.d service
cat > /etc/init.d/sevpn << EOF
#!/bin/sh /etc/rc.common
START=99
STOP=15
### Server IP
SERVER=$SERVER
### Custom DNS (Let’s avoid DNS leaks)
DNS1=$DNS1
DNS2=$DNS2
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
	printf '%s\n' "Your new IP address is: \$IP4"
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
		LEDVPN=\$(/bin/ls /sys/class/leds/ | awk '/:wan/ || /:lan/ { print \$0 }')
		echo netdev> /sys/class/leds/\$LEDVPN/trigger
		echo vpn_0> /sys/class/leds/\$LEDVPN/device_name
		echo 'link tx rx'> /sys/class/leds/\$LEDVPN/mode
		echo \$DNIC > "/tmp/sevpn-dnic"
		ip r flush table main
		route add -net 192.168.8.0 netmask 255.255.255.0 dev br-lan
		udhcpc -i \$DNIC -q
		uci set dhcp.@dnsmasq[0].server=\$DNS1
		uci add_list dhcp.@dnsmasq[0].server=\$DNS2
		uci set dhcp.@dnsmasq[0].noresolv='1'
		uci set glconfig.general.auto_dns='0'
		uci set glconfig.general.manual_dns='1'
		uci commit dhcp
		uci commit glconfig.general
		/etc/init.d/dnsmasq restart
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
		sleep 1
		STATUS=\$(vpncmd localhost /CLIENT /CMD AccountStatusGet \$ACCOUNT | sed -n -e 's/^.*Session Status                            |//p')
		if [ "\$STATUS" = "Connection Completed (Session Established)" ]; then
			proceed
		else
			vpncmd localhost /CLIENT /CMD AccountDisconnect vpn_0
			sleep 2
			connect
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
				sleep 9
				STATUS=\$(vpncmd localhost /CLIENT /CMD AccountStatusGet \$ACCOUNT | sed -n -e 's/^.*Session Status                            |//p')
				if [ "\$STATUS" = "Connection Completed (Session Established)" ]; then
					proceed
				else
						vpncmd localhost /CLIENT /CMD AccountDisconnect vpn_0
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
		LEDVPN=\$(/bin/ls /sys/class/leds/ | awk '/:wan/ || /:lan/ { print \$0 }')
		vpncmd localhost /CLIENT /CMD AccountDisconnect vpn_0
		echo 'none'> /sys/class/leds/\$LEDVPN/mode
		uci delete dhcp.@dnsmasq[0].server
		uci delete dhcp.@dnsmasq[0].noresolv
		uci set glconfig.general.manual_dns='0'
		uci set glconfig.general.auto_dns='1'
		uci commit dhcp
		uci commit glconfig.general
		/etc/init.d/dnsmasq restart
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

# Configure switch button for VPN
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

# Disable initswitch since it has been integrated in sevpn
/etc/init.d/initswitch disable

# Enable switch button
uci set glconfig.switch_button=service
uci set glconfig.switch_button.enable='1'
uci set glconfig.switch_button.function='sevpn'
cat <<EOT >> /etc/rc.local
uci set glconfig.switch_button=service
uci set glconfig.switch_button.enable='1'
uci set glconfig.switch_button.function='sevpn'
EOT

# Finish and ask for connection
echo VPN is ready.
sleep 1
echo 'Use side switch to start/stop VPN. (Left = ON / Right = OFF)'
SWITCH_LEFT=$(grep -o "left.*hi" /sys/kernel/debug/gpio)
if [ -n "$SWITCH_LEFT" ]; then
	read -t 10 -r -p "Side switch is currently turned left. Establish connection now? [y/N] " response
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
			echo Proceeding due to a timeout…
			sleep 1
			echo Starting VPN connection…
			/etc/init.d/sevpn start
		;;
	esac
else
	sleep 1
	echo Side switch is currently turned right. VPN remains disconnected.
	exit 0
fi
