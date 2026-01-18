#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
	echo "Usage: $0 <interface>.<desired_mtu>"
	exit 1
fi

INTERFACE="${1%%.*}"
DESIRED_MTU="${1#*.}"

if ! ip addr show dev "$INTERFACE" &>/dev/null; then
	echo "Interface $INTERFACE does not exist."
	exit 1
fi
if ! [[ "$DESIRED_MTU" =~ ^[0-9]+$ ]]; then
	echo "Invalid MTU value: $DESIRED_MTU"
	exit 1
fi

# Check if the initial setting was successful
if ! output=$(ip link set dev "$INTERFACE" mtu "$DESIRED_MTU" 2>&1); then
	echo "Failed to set MTU to $DESIRED_MTU on interface $INTERFACE"
	echo "$output"
	exit 1
fi

# Start monitoring link changes for the interface
ip monitor link dev "$INTERFACE" | while read -r _; do
	# Check current MTU
	current_mtu=$(ip link show dev "$INTERFACE" | awk '/mtu/ {for (i=1;i<=NF;i++) if ($i=="mtu") print $(i+1)}')

	# If MTU is not what we want, reset it
	if [[ -n "$current_mtu" && "$current_mtu" -ne "$DESIRED_MTU" ]]; then
		echo "[$(date)] MTU changed to $current_mtu, resetting to $DESIRED_MTU"
		ip link set dev "$INTERFACE" mtu "$DESIRED_MTU"
	fi
done
