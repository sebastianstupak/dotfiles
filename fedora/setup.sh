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

# Install Firefox plugins
sudo dnf install -y gstreamer1-plugin-openh264 mozilla-openh264

# Install Git and all related tools
sudo dnf install -y git-all

# Install Neovim
sudo dnf install -y neovim

# Ensure Flathub repository is added
if ! flatpak remotes | grep -q flathub; then
  echo "Adding Flathub repository..."
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Update Flatpak repositories
sudo flatpak update -y

# Install WezTerm via Flatpak
if ! flatpak list | grep -q org.wezfurlong.wezterm; then
  echo "Installing WezTerm..."
  flatpak install -y flathub org.wezfurlong.wezterm
fi

# Install tmux
sudo dnf install tmux

# Install tmux plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

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
else
  echo "User $target_user does not exist. Please check the username and try again."
  exit 1
fi

echo "Setup complete!"
