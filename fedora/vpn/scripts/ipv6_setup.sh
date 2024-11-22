#!/bin/bash

# First disable main IPv6 settings
sudo tee "/etc/sysctl.d/40-ipv6-disable.conf" > /dev/null << 'CONF'
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
CONF

# Apply initial settings
sudo sysctl -p "/etc/sysctl.d/40-ipv6-disable.conf"

# Create script to disable IPv6 for new interfaces
sudo mkdir -p "/etc/NetworkManager/dispatcher.d/pre-up.d"
sudo tee "/etc/NetworkManager/dispatcher.d/pre-up.d/disable-ipv6" > /dev/null << 'SCRIPT'
#!/bin/bash
interface="$1"
if [ -e "/proc/sys/net/ipv6/conf/$interface/disable_ipv6" ]; then
    echo 1 > "/proc/sys/net/ipv6/conf/$interface/disable_ipv6"
fi
SCRIPT

# Make the script executable
sudo chmod +x "/etc/NetworkManager/dispatcher.d/pre-up.d/disable-ipv6"

# Restart NetworkManager
sudo systemctl restart NetworkManager
