#!/bin/bash

# Ensure the script is run with superuser privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (e.g., using sudo)"
  exit 1
fi

# Install Firefox plugins
sudo dnf install -y gstreamer1-plugin-openh264 mozilla-openh264

# Install Git and all related tools
sudo dnf install -y git-all

# Install Neovim
sudo dnf install -y neovim

# Set vim command to use nvim by default
sudo update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60

# Determine the directory of this script
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set the path to the dotfiles' nvim directory
nvim_config_source="$script_dir/nvim"

# Neovim configuration destination
nvim_config_dest="$HOME/.config/nvim"

# Create the Neovim configuration directory if it doesn't exist
mkdir -p "$nvim_config_dest"

# Link the init.lua from the dotfiles repository
if [ -f "$nvim_config_source/init.lua" ]; then
  ln -sf "$nvim_config_source/init.lua" "$nvim_config_dest/init.lua"
  echo "Neovim configuration linked successfully."
else
  echo "init.lua not found in $nvim_config_source!"
fi
