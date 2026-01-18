#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_SCRIPT="$SCRIPT_DIR/set-interface-mtu.sh"
SRC_SERVICE="$SCRIPT_DIR/set-interface-mtu@.service"
DEST_SCRIPT="/usr/local/bin/set-interface-mtu.sh"
DEST_SERVICE="/etc/systemd/system/set-interface-mtu@.service"

usage() {
	cat <<EOF
Usage: $0 <install|uninstall|help> [INSTANCE]

Commands:
  install      Copy files to system locations and reload systemd (if available).
  uninstall    Remove installed files and reload systemd (if available).
  help         Show this message.

Optional INSTANCE (for install): when provided, the installer will also enable and
start the systemd template instance named "set-interface-mtu@<INSTANCE>.service".
Example INSTANCE: "eth0.1500" (the string used in place of %i in the unit).
EOF
	exit 1
}

require_file_exists() {
	if [[ ! -f "$1" ]]; then
		echo "Required file not found: $1"
		exit 1
	fi
}

copy_root_safe() {
	local src=$1 dest=$2
	if [[ -w "$(dirname "$dest")" ]]; then
		cp "$src" "$dest"
	else
		sudo cp "$src" "$dest"
	fi
}

chmod_root_safe() {
	local mode=$1 file=$2
	if [[ -w "$file" ]]; then
		chmod "$mode" "$file"
	else
		sudo chmod "$mode" "$file"
	fi
}

systemctl_available() {
	command -v systemctl >/dev/null 2>&1
}

install() {
	if ! systemctl_available; then
		echo "systemctl not found: skipping installation."
		exit 1
	fi

	require_file_exists "$SRC_SCRIPT"
	require_file_exists "$SRC_SERVICE"

	echo "Installing script -> $DEST_SCRIPT"
	copy_root_safe "$SRC_SCRIPT" "$DEST_SCRIPT"
	chmod_root_safe +x "$DEST_SCRIPT"

	echo "Installing unit -> $DEST_SERVICE"
	copy_root_safe "$SRC_SERVICE" "$DEST_SERVICE"

	echo "Reloading systemd daemon"
	sudo systemctl daemon-reload

	if [[ -n "${INSTANCE:-}" ]]; then
		echo "Enabling and starting instance: set-interface-mtu@${INSTANCE}.service"
		sudo systemctl enable --now "set-interface-mtu@${INSTANCE}.service"
	else
		echo "Unit installed. To enable for an interface run:"
		echo "  sudo systemctl enable --now set-interface-mtu@<interface>.<mtu>.service"
	fi

	echo "Install complete."
}

uninstall() {
	if systemctl_available && [[ -n "${INSTANCE:-}" ]]; then
		echo "Stopping and disabling instance: set-interface-mtu@${INSTANCE}.service"
		sudo systemctl stop "set-interface-mtu@${INSTANCE}.service" || true
		sudo systemctl disable "set-interface-mtu@${INSTANCE}.service" || true
	fi

	if [[ -f "$DEST_SERVICE" ]]; then
		echo "Removing unit: $DEST_SERVICE"
		if [[ -w "$(dirname "$DEST_SERVICE")" ]]; then
			rm -f "$DEST_SERVICE"
		else
			sudo rm -f "$DEST_SERVICE"
		fi
	fi

	if [[ -f "$DEST_SCRIPT" ]]; then
		echo "Removing script: $DEST_SCRIPT"
		if [[ -w "$(dirname "$DEST_SCRIPT")" ]]; then
			rm -f "$DEST_SCRIPT"
		else
			sudo rm -f "$DEST_SCRIPT"
		fi
	fi

	if systemctl_available; then
		echo "Reloading systemd daemon"
		sudo systemctl daemon-reload
	fi

	echo "Uninstall complete."
}

# Main
if [[ $# -lt 1 ]]; then
	usage
fi

ACTION=$1
INSTANCE=""
if [[ $# -ge 2 ]]; then
	INSTANCE=$2
fi

case "$ACTION" in
install)
	install
	;;
uninstall)
	uninstall
	;;
help | --help | -h)
	usage
	;;
*)
	echo "Unknown action: $ACTION"
	usage
	;;
esac
