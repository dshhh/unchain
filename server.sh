#!/bin/sh
# This install script builds the latest stable version of SoftEther VPN, and configures SecureNAT, a virtual hub and a user

# Generic variables
USERNM=unchain_default
HUB=vhub

# User variables
read -p 'Set VPN user password (Use letters and numbers [a-zA-Z0-9], periods [.], and/or exclamation marks [!]): ' PASSWD
USERNMLC=$(echo "$USERNM" | tr '[:upper:]' '[:lower:]')

echo "OK. Installing..."

# Add user to run service in user space
adduser --disabled-password --gecos '' $USERNMLC
usermod -aG sudo $USERNMLC
#printf "$PASSWD\n$PASSWD" | passwd $USERNMLC
sed -i -e '$i '"$USERNMLC"' ALL = NOPASSWD : ALL\n' /etc/sudoers

# Install SoftEther VPN
git clone https://github.com/SoftEtherVPN/SoftEtherVPN_Stable.git
cd ./SoftEtherVPN_Stable
./configure
make
make install

# Start and setup SoftEther VPN, enable SecureNAT, create a virtual hub and a user, and set a password
sudo -u "$USERNMLC" -H sh -c "
sudo vpnserver start &&
sleep 1 &&
sudo vpncmd /SERVER localhost /CMD HubCreate ""\"$HUB\""" /PASSWORD:""\"$PASSWD\""" >/dev/null &&
sudo vpncmd /SERVER localhost /HUB:""\"$HUB\""" /PASSWORD:""\"$PASSWD\""" /CMD SecureNatEnable &&
sudo vpncmd /SERVER localhost /HUB:""\"$HUB\""" /PASSWORD:""\"$PASSWD\""" /CMD UserCreate $USERNM /GROUP:none /REALNAME:none /NOTE:none &&
sudo vpncmd /SERVER localhost /HUB:""\"$HUB\""" /PASSWORD:""\"$PASSWD\""" /CMD UserPassword $USERNM /PASSWORD:""\"$PASSWD\""" >/dev/null
"
retVal=$?

# Exit
if [ $retVal -ne 0 ]; then
	echo "Unknown Error."
elif [ $retVal -eq 0 ]; then
	echo "SoftEther VPN is ready."
	exit $retVal
fi
if [ $retVal -eq 57 ]; then
	echo "A Virtual Hub with the specified name already exists on the server."
	exit $retVal
fi
if [ $retVal -eq 66 ]; then
	echo "A user with the specified name already exists for this Virtual Hub."
	exit $retVal
fi
