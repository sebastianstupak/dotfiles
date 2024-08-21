#!/bin/bash

# Ensure the script is run with superuser privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (e.g., using sudo)"
  exit 1
fi

# Append configuration to /etc/dnf/dnf.conf for speed optimization
dnf_conf="/etc/dnf/dnf.conf"
if ! grep -q "# Speed optimization" "$dnf_conf"; then
  echo -e "\n# Speed optimization\nfastestmirror=True\nmax_parallel_downloads=5\nkeepcache=True" | sudo tee -a "$dnf_conf"
fi

# Update DNF
sudo dnf update -y

# Install RPM Fusion repositories
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
                    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Update core group packages
sudo dnf groupupdate core -y

# Update multimedia group excluding weak dependencies
sudo dnf groupupdate multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y

# Update sound-and-video group
sudo dnf groupupdate sound-and-video -y

echo "Fedora-specific setup complete!"
