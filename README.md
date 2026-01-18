# set-interface-mtu

Small helper to set and persist an MTU on a network interface using a systemd template service.

## Unifi Cloud Gateway

I am using this to be able to implement [RFC 4638](https://www.rfc-editor.org/rfc/rfc4638.html) in order to use baby jumbo frames over a PPPoE connection on a Unifi Cloud Gateway Fibre.

For this use, I need to enable the service on 2 interfaces with a desired MTU of 1508:

* `switch0`: required otherwise the other interface fails
* `eth4`: this maps to the RJ45 port 4 on the device, which is the one originally marked to be used as WAN. Adjust this if using a different port.

To accomplish that, I run the installation script twice:

```
./install.sh install switch0.1508
./install.sh install eth4.1508
```

Despite the above, this utility should work on any Linux system with systemd.

## Requirements

- Linux with `systemd` (for the service template). The script itself uses `bash` and `ip` (iproute2).
- Root privileges to install or enable systemd units.

## Install

Make the installer executable then install the files:

```bash
chmod +x install.sh
sudo ./install.sh install
```

To install and immediately enable/run a specific instance (example: set MTU 1500 on `eth0`):

```bash
sudo ./install.sh install eth0.1500
# or manually after install
sudo systemctl enable --now set-interface-mtu@eth0.1500.service
```

Note: `install.sh` will prompt for `sudo` where needed; running it with `sudo` ensures the unit is enabled immediately.

## Uninstall

To remove the files and (optionally) stop a running instance:

```bash
sudo ./install.sh uninstall eth0.1500
# or to remove files only
sudo ./install.sh uninstall
```

## Using the systemd template

The template instance name must be the interface and desired MTU joined by a dot: `<interface>.<mtu>`.

Examples:

- `set-interface-mtu@eth0.1500.service` — sets MTU 1500 on `eth0`.
- `sudo systemctl start set-interface-mtu@eth0.1400.service` — start without enabling on boot.

## Logging & troubleshooting

Check service logs with:

```bash
sudo journalctl -u set-interface-mtu@eth0.1500.service -f
```

If the script reports "Interface ... does not exist", verify the interface name with `ip link`.

## License

See the `LICENSE` file in this repository.
