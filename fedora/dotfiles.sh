#!/bin/bash

# Ensure the script is run with superuser privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (e.g., using sudo)"
  exit 1
fi

# Prompt for the target username
read -p "Enter the target username: " target_user

# Check if the user exists
if ! id "$target_user" &>/dev/null; then
  echo "User '$target_user' does not exist!"
  exit 1
fi

# Determine the directory of this script
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dotfiles_dir="$script_dir/../"  # Go one level up to /dotfiles

# Set the path to the dotfiles' nvim, wezterm, and tmux directories
nvim_config_source="$dotfiles_dir/nvim"
wezterm_config_source="$dotfiles_dir/wezterm/wezterm.lua"
tmux_config_source="$dotfiles_dir/tmux/tmux.conf"

# Specify the target user's home directory
target_home=$(eval echo ~$target_user)

# Neovim, WezTerm, and tmux configuration destinations
nvim_config_dest="$target_home/.config/nvim"
wezterm_config_dest="$target_home/.config/wezterm"
tmux_config_dest="$target_home/.config/tmux"

# Remove existing Neovim configuration directory if it exists
if [ -d "$nvim_config_dest" ]; then
  rm -rf "$nvim_config_dest"
fi

# Link the entire nvim folder from the dotfiles repository
if [ -d "$nvim_config_source" ]; then
  ln -s "$nvim_config_source" "$nvim_config_dest"
  echo "Neovim configuration folder linked successfully for user '$target_user'."
else
  echo "Neovim configuration folder not found in $nvim_config_source!"
fi

# Create the WezTerm configuration directory if it doesn't exist
mkdir -p "$wezterm_config_dest"

# Link the wezterm.lua from the dotfiles repository for WezTerm
if [ -f "$wezterm_config_source" ]; then
  ln -sf "$wezterm_config_source" "$wezterm_config_dest/wezterm.lua"
  echo "WezTerm configuration linked successfully for user '$target_user'."
else
  echo "wezterm.lua not found in $wezterm_config_source!"
fi

# Create the tmux configuration directory if it doesn't exist
mkdir -p "$tmux_config_dest"

# Check if tmux.conf exists in the ~/.config/tmux directory, if not create a basic one
if [ ! -f "$tmux_config_dest/tmux.conf" ]; then
  echo "tmux.conf not found in $tmux_config_dest. Creating a basic configuration."
  cat << EOF > "$tmux_config_dest/tmux.conf"
# Basic tmux configuration
set -g default-terminal "screen-256color"
set -g history-limit 10000
set -g status-bg black
set -g status-fg white
EOF
fi

# Link the tmux.conf from the dotfiles repository to ~/.config/tmux/tmux.conf
if [ -f "$tmux_config_source" ]; then
  ln -sf "$tmux_config_source" "$tmux_config_dest/tmux.conf"
  echo "tmux configuration linked successfully for user '$target_user'."
else
  echo "tmux.conf not found in $tmux_config_source. Using the basic configuration."
fi

echo "Dotfiles setup complete for user '$target_user'!"
