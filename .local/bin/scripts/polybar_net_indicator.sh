#!/bin/bash
#
# Show a custom network connection indicator in polybar.
# Includes code for wifi, VPN, ZeroTier, and Hamachi.
#
# Author: machaerus
# https://gitlab.com/machaerus

source /home/hustin/.local/bin/scripts/colors.sh

net_print() {

	CONNECTED_WIFI=$(cat /sys/class/net/wlp4s0/carrier)
	#ESSID=$(iwconfig wlan0 | grep ESSID | cut -d: -f2 | xargs)
	#[ "$ESSID" = "off/any" ] && CONNECTED_WIFI=0 || CONNECTED_WIFI=1
	# CONNECTED_VPN=$(ifconfig -a | grep tun0 | wc -l)
        CONNECTED_VPN=$(printf "VPN: " && (pgrep -a openvpn$ | head -n 1 | awk '{print $NF }' | cut -d '.' -f 1 && echo down) | head -n 1)
        CONNECTED_LAN=$(cat /sys/class/net/enp3s0/carrier)
	
	if [ "$CONNECTED_WIFI" = 1 ]; then
		wifi_indicator="${bright_blue}直${RESET}"
	else
		wifi_indicator="${dark0_soft}直${RESET}"
	fi

        if [ "$CONNECTED_LAN" -eq 1 ]; then
                lan_indicator="${bright_blue}ﯱ ${RESET}"
        else
                lan_indicator="${dark0_soft}ﯱ ${RESET}"
        fi

	if [ "$CONNECTED_VPN" = "VPN: nm-openvpn" ]; then
		vpn_indicator="${bright_blue} ${RESET}"
	else
		vpn_indicator="${dark0_soft} ${RESET}"
	fi

	
	
	# echo "$dark2[$wifi_indicator$dark2]$dark2[$vpn_indicator$dark2]"
	echo "$dark0_soft[ $wifi_indicator  $lan_indicator $vpn_indicator$dark0_soft]"
	# echo " $wifi_indicator $vpn_indicator "
}

net_print

