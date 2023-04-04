#!/bin/bash

#
# Script for start Checkpoint VPN and fix DNS issues on F34.
# Tested on Fedora 34 and my work VPN.
# Author: Stanislav V. Emets <stas@emets.su>
#

# Default values
ACTION=""
PROFILE=""
CONFIG="snx.conf"
SNX_STATUS_FILE="snx.status"
PASSWORD=""

# Parse command line arguments
while [ $# -gt 0 ]; do
	key="$1"
	case $key in
		-p|--profile)
		PROFILE="$2"
		shift
		shift
		;;
		-c|--config)
		CONFIG="$2"
		shift
		shift
		;;
		-h|--help)
		usage
		shift
		;;
		*)
		ACTION="$1"
		shift
		;;
	esac
done

function usage() {
cat <<EOH

Script for start or stop Checkpoint VPN (SNX) and fix issues with DNS and routes
this script tested only for my work only, but with minimal adoption can work
for others.

Usage:
    up-snx.sh [-p|--profile /path/to/profile] [-c|--config /path/to/config] <start|stop>

       -p|--profile - Path to profile. Profile is a file with values for variables, see profile.sample
                      Default: empty value.
       -c|--config  - Path to config, see snx.conf.sample. Default: snx.conf in current directory or
                      can been replaced in profile file.
       -h|--help    - Print this help.
EOH
}

EXTRA_ROUTES=""
NEW_ROUTES=""

if [ -f "$PROFILE" ]; then
    . "$PROFILE"
else
    usage
fi

if [ "$ACTION" == "start" ]; then
    if [ ! -f "$CONFIG" ]; then
        echo "Config file not found!"
        usage
        exit 1
    fi

    if [ -n "$PASSWORD" ]; then
        echo "${PASSWORD}" | snx -f "$CONFIG" > ${SNX_STATUS_FILE}
    else
        echo "Please enter your password:"
        snx -f "$CONFIG" > ${SNX_STATUS_FILE}
    fi

    if [ $? -eq 0 ]; then
        DNS=$(grep "DNS Server" ${SNX_STATUS_FILE} | tr -s " " | cut -d ":" -f 2 | tr -s "\n" " ")
        if [ -n "$DNS" ]; then
            sudo resolvectl dns tunsnx $DNS
        fi

        DOMAINS=$(grep "DNS Suffix" ${SNX_STATUS_FILE} | cut -d ":" -f 2 | tr -s ";" " ")
        if [ -n "$DOMAINS" ]; then
            sudo resolvectl domain tunsnx $DOMAINS
        fi

        # Extra domains in addition that snx return
        if [ -n "$EXTRA_DOMAINS" ]; then
            sudo resolvectl domain tunsnx $EXTRA_DOMAINS
        fi

        # Replace routes from SNX to own configured
        if [ -n "$NEW_ROUTES" ]; then
            OLD_ROUTES=$(ip r | grep tunsnx)
            if [ -n "$OLD_ROUTES" ]; then
                OLD_ROUTES=${OLD_ROUTES// /|}
                for old_route in "${OLD_ROUTES[@]}"; do
                    sudo ip route del "${old_route//|/ }"
                done
            fi

            # Add new routes
            for new_route in $NEW_ROUTES; do
                sudo ip route add "$new_route" dev tunsnx
            done
        fi

        # Add extra routes from configuration
        if [ -n "$EXTRA_ROUTES" ]; then
            for extra_route in $EXTRA_ROUTES; do
                sudo ip route add "$extra_route" dev tunsnx
            done
        fi

       echo ''
       cat ${SNX_STATUS_FILE}
       exit 0
    else
        echo "SNX not started!"
    fi
elif [ "$ACTION" == "stop" ]; then
    # delete extra routes
    if [ -n "$EXTRA_ROUTES" ]; then
        for extra_route in $EXTRA_ROUTES; do
            sudo ip route del "$extra_route" dev tunsnx
        done
    fi
    if [ -n "$NEW_ROUTES" ]; then
        for new_route in $NEW_ROUTES; do
            sudo ip route del "$new_route" dev tunsnx
        done
    fi
    echo "Revert DNS configuration"
    sudo resolvectl revert tunsnx
    sudo resolvectl flush-caches

    echo "Stopping SNX vpn"
    snx -d
else
	usage
    exit 1
fi
