#!/bin/bash
set -e          #Exit as soon as any line in the bash script fails
#set -x          #Prints each command executed (prefix with ++)

# Adapted from:
# https://learn.adafruit.com/setting-up-a-raspberry-pi-as-a-wifi-access-point?view=all

# CONFIG FILES TO BE MODIFIED, IN ORDER:
# Note: This script makes backups of all the files it modifies.
#
# /etc/dhcp/dhcpd.conf          # overwrite
# /etc/default/isc-dhcp-server  # overwrite
# /etc/network/interfaces       # overwrite
# /etc/hostapd/hostapd.conf     # overwrite
# /etc/default/hostapd          # overwrite
# /etc/sysctl.conf              # use augeas
# /etc/network/interfaces       # (this time, add to end)

mk_bak () {
    # This function makes a backup of the file, iff it exists
    if [ -e "$1" ]
    then
        DATETIME=$(date "+%Y%m%d_%H%M%S") # alternatively "+%F_%T"
        cp "$1" "$1.$DATETIME.OnionPi.orig"
    fi
}

/bin/echo "Make sure system is up to date"
/usr/bin/apt-get update -y
/usr/bin/apt-get upgrade -y

/bin/echo "Install augeas tool for config management"
/usr/bin/apt-get install -y libaugeas0 augeas-lenses augeas-tools

echo "Install hostapd and isc-dhcp-server"
/usr/bin/apt-get install -y hostapd isc-dhcp-server

/bin/echo "Configure DHCP"

DHCPD_CONF="/etc/dhcp/dhcpd.conf"
mk_bak $DHCPD_CONF
/bin/cat /dev/null > $DHCPD_CONF
/bin/cat <<'EOF_dhcp_conf' > $DHCPD_CONF
ddns-update-style none;

default-lease-time 600;
max-lease-time 7200;

authoritative;

log-facility local7;

subnet 192.168.42.0 netmask 255.255.255.0 {
  range 192.168.42.10 192.168.42.50;
  option broadcast-address 192.168.42.255;
  option routers 192.168.42.1;
  default-lease-time 600;
  max-lease-time 7200;
  option domain-name "local";
  option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOF_dhcp_conf

ISC_DHCP_SERV="/etc/default/isc-dhcp-server"
mk_bak $ISC_DHCP_SERV
/bin/cat /dev/null > $ISC_DHCP_SERV
cat <<EOF > $ISC_DHCP_SERV
INTERFACES="wlan0"
EOF

/bin/echo "Deactivate the wifi in case it was up"
sudo ifdown wlan0

/bin/echo "Set up the wlan0 connection to be static and incoming"
NET_IFACES="/etc/network/interfaces"
mk_bak $NET_IFACES
/bin/cat /dev/null > $NET_IFACES
cat <<EOF > $NET_IFACES
auto lo

iface lo inet loopback
iface eth0 inet dhcp

allow-hotplug wlan0

iface wlan0 inet static
  address 192.168.42.1
  netmask 255.255.255.0
EOF

/bin/echo "Assign a static IP address to the wifi adapter"
sudo ifconfig wlan0 192.168.42.1

/bin/echo "Configure the access point"
HOSTAPD_CONF="/etc/hostapd/hostapd.conf"
/bin/cat /dev/null > $HOSTAPD_CONF
cat <<EOF > $HOSTAPD_CONF
interface=wlan0
# driver=rtl871xdrv
hw_mode=g
channel=6
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP

ssid=OnionPi
wpa_passphrase=changemeplease!
EOF

/bin/echo "Tell hostapd where to find this configuration file"
ETC_DEFAULT_HOSTAPD="/etc/default/hostapd"
mk_bak $ETC_DEFAULT_HOSTAPD
cat <<EOF > $ETC_DEFAULT_HOSTAPD
DAEMON_CONF="/etc/hostapd/hostapd.conf"
EOF

/bin/echo "Configure Network Address Translation"
SYSCTL_CONF="/etc/sysctl.conf"
mk_bak $SYSCTL_CONF
# augtool set /files/etc/sysctl.conf/net.ipv4.ip_forward 1
augtool set /files$SYSCTL_CONF/net.ipv4.ip_forward 1

/bin/echo "Start NAT forwarding immediately"
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

/bin/echo "Configure iptables for network translation between eth0 and wlan0"
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT

/bin/echo "Save iptables config for persistence across reboots"
/bin/sh -c "iptables-save > /etc/iptables.ipv4.nat"

# We already made a backup of this file the first time around, when we
# set this variable too. APPEND TO END OF FILE! (This time around.)
/bin/echo "Add the saved iptables config to our network config"
/bin/cat <<'EOF' >> $NET_IFACES

up iptables-restore < /etc/iptables.ipv4.nat
EOF

replace_hostapd_with_different_binary () {
    # This function is called from: check_wifi_module_and_maybe_replace_hostapd
    echo "Replacing system hostapd with a binary downloaded from Adafruit. \
Kludge for making access point mode work with the Realtek adapter."

    /usr/bin/wget https://adafruit-download.s3.amazonaws.com/adafruit_hostapd_14128.zip
    # TODO: save this to a tmp location!

    /bin/echo "Checking that this matches the hash we expect"
    # This is (should be) the SHA-256 hash for file: adafruit_hostapd_14128.zip
    OUR_HASH="abb9eb6bf8ffd2d334f7e47c7c0c5e4f1185264baf743c0e4796163c50ad9607"

    # Note also that the binary once extracted has the following SHA-256:
    # a9fb4692741f97cf358f678867804385b25f10cf6df60e05575cc61ddcdaacae  hostapd

    /usr/bin/sha256sum adafruit_hostapd_14128.zip | grep "$OUR_HASH"
    if [ $? -eq 0 ] # return val 0: grep found a match
    then
        /bin/echo "Yes, it matches. Extracting and installing the binary."
        # The zip just contains the binary "hostapd"
        /usr/bin/unzip adafruit_hostapd_14128.zip
        # Make a backup of the original binary, then delete it
        mk_bak /usr/sbin/hostapd && /bin/rm /usr/sbin/hostapd

        /bin/mv hostapd /usr/sbin # Move the Adafruit binary into place
        /bin/chmod 755 /usr/sbin/hostapd # Set it up so it's valid to run
    else
        /bin/echo "
################################################
WARNING! Hash doesn't match. Skipping this step.
################################################
"
    fi
}

check_wifi_module_and_maybe_replace_hostapd () {
    /bin/echo "Certain Realtek wifi adapters need a modified version of hostapd. \
Checking our model..."

    lsusb | grep "RTL8188CUS"
    if [ $? -eq 0 ] # return val 0: grep found a match
    then
        /bin/echo "Yes, we found it and need to replace"
        replace_hostapd_with_different_binary
    else
        /bin/echo "Not the module we are looking for, carry on..."
    fi
}

check_wifi_module_and_maybe_replace_hostapd

echo "Start the services now"
service hostapd start
service isc-dhcp-server start

echo "Enable the services at boot time"
update-rc.d hostapd enable
update-rc.d isc-dhcp-server enable

/bin/echo "Access point set up!"

/bin/echo "
###############################
Note:

Depending on your distro, you may need to remove WPASupplicant (and reboot).

To do so, you can use the following commands:

  sudo mv /usr/share/dbus-1/system-services/fi.epitest.hostap.WPASupplicant.service ~/
  sudo reboot

###############################
"
