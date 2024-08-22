#!/bin/bash

# Check if the script is run with sudo privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo privileges."
  exit 1
fi

# Update sound-and-video group
dnf groupupdate sound-and-video -y

# Install Firefox plugins
dnf install -y gstreamer1-plugin-openh264 mozilla-openh264

# Install Git and all related tools
dnf install -y git-all

# Install Neovim
dnf install -y neovim

# Ensure Flathub repository is added
if ! flatpak remotes | grep -q flathub; then
  echo "Adding Flathub repository..."
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Update Flatpak repositories
flatpak update -y

# Install WezTerm via Flatpak
if ! flatpak list | grep -q org.wezfurlong.wezterm; then
  echo "Installing WezTerm..."
  flatpak install -y flathub org.wezfurlong.wezterm
fi

# Install tmux
dnf install -y tmux

# Install Zellij
install_zellij() {
  echo "Installing Zellij..."
  ZELLIJ_VERSION=$(curl -s https://api.github.com/repos/zellij-org/zellij/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
  ZELLIJ_URL="https://github.com/zellij-org/zellij/releases/download/${ZELLIJ_VERSION}/zellij-x86_64-unknown-linux-musl.tar.gz"
  
  # Download and extract Zellij
  curl -L "$ZELLIJ_URL" | tar xz -C /usr/local/bin
  
  # Make Zellij executable
  chmod +x /usr/local/bin/zellij
  
  echo "Zellij ${ZELLIJ_VERSION} has been installed."
}

# Check if Zellij is already installed
if ! command -v zellij &> /dev/null; then
  install_zellij
else
  echo "Zellij is already installed."
fi

# Prompt for the target username
read -p "Enter the username for which you want to set up aliases: " target_user

# Check if the user exists
if id "$target_user" &>/dev/null; then
  user_home=$(eval echo ~$target_user)
  bashrc="$user_home/.bashrc"
  bashrc_d="$user_home/.bashrc.d"
  aliases_file="$bashrc_d/aliases"
  profile="$user_home/.profile"

  # Create .bashrc.d directory if it doesn't exist
  if [ ! -d "$bashrc_d" ]; then
    echo "Creating $bashrc_d directory..."
    mkdir -p "$bashrc_d"
    chown $target_user:$target_user "$bashrc_d"
    chmod 755 "$bashrc_d"
  fi

  # Create or append to the aliases file
  touch "$aliases_file"

  # Function to add alias if it doesn't exist
  add_alias() {
    local alias_name="$1"
    local alias_command="$2"
    if ! grep -q "alias $alias_name=" "$aliases_file"; then
      echo "Adding alias for $alias_name..."
      echo "alias $alias_name='$alias_command'" >> "$aliases_file"
    else
      echo "Alias for $alias_name already exists in $aliases_file"
    fi
  }

  # Add aliases
  add_alias "wezterm" "flatpak run org.wezfurlong.wezterm"
  add_alias "vim" "nvim"

  # Ensure XDG_DATA_DIRS includes Flatpak applications
  if ! grep -q "XDG_DATA_DIRS.*flatpak" "$aliases_file"; then
    echo "Adding Flatpak directories to XDG_DATA_DIRS..."
    echo 'export XDG_DATA_DIRS="$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share"' >> "$aliases_file"
  fi

  # Ensure the aliases file has the correct permissions
  chown $target_user:$target_user "$aliases_file"
  chmod 644 "$aliases_file"

  # Modify .bashrc to source files in .bashrc.d
  if ! grep -q "Source user-specific configuration files" "$bashrc"; then
    echo "Modifying .bashrc to source files in .bashrc.d..."
    echo '
# Source user-specific configuration files
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
' >> "$bashrc"
  fi

  # Ensure .profile sources .bashrc
  if [ ! -f "$profile" ] || ! grep -q ". ~/.bashrc" "$profile"; then
    echo "Ensuring .profile sources .bashrc..."
    echo '
# Source .bashrc if it exists
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
' >> "$profile"
  fi

  echo "Aliases and XDG_DATA_DIRS updates added to $aliases_file."
  echo ".bashrc has been updated to source files in .bashrc.d"
  echo ".profile has been updated to source .bashrc"
  echo "Please log out and log back in to apply all changes."

  # Install tmux plugin manager for the target user
  sudo -u $target_user git clone https://github.com/tmux-plugins/tpm $user_home/.tmux/plugins/tpm
else
  echo "User $target_user does not exist. Please check the username and try again."
  exit 1
fi

echo "Setup complete!"
