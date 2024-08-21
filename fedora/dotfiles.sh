#!/bin/bash

# Ensure the script is run with superuser privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (e.g., using sudo)"
  exit 1
fi

# Determine the directory of this script
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dotfiles_dir="$script_dir/code/dotfiles"

# Set the path to the dotfiles' nvim directory
nvim_config_source="$dotfiles_dir/nvim/init.lua"

# Neovim configuration destination
nvim_config_dest="$HOME/.config/nvim"

# Create the Neovim configuration directory if it doesn't exist
mkdir -p "$nvim_config_dest"

# Link the init.lua from the dotfiles repository
if [ -f "$nvim_config_source" ]; then
  ln -sf "$nvim_config_source" "$nvim_config_dest/init.lua"
  echo "Neovim configuration linked successfully."
else
  echo "init.lua not found in $nvim_config_source!"
fi

echo "Dotfiles setup complete!"
