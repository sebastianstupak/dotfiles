#!/bin/bash

# Check if the script is run with sudo privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo privileges."
  exit 1
fi

# Function to ask for permission
ask_permission() {
    read -p "Do you want to $1 (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        return 0
    else
        return 1
    fi
}

# Function to check if a package is installed
is_installed() {
    if dnf list installed "$1" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to remove existing entries and append new content
update_file_content() {
    local file="$1"
    local marker="$2"
    local content="$3"

    echo "Updating file: $file"
    # Remove existing entries
    sed -i "/$marker/,/^$/d" "$file"

    # Append new content
    echo "$content" >> "$file"

    # Remove duplicates
    awk '!seen[$0]++' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    echo "File updated: $file"
}

# Update system packages
if ask_permission "update system packages"; then
    echo "Updating system packages..."
    dnf update -y
    echo "System packages updated."
fi

# Update sound-and-video group
if ask_permission "update sound-and-video group"; then
    echo "Updating sound-and-video group..."
    dnf groupupdate sound-and-video -y
    echo "Sound-and-video group updated."
fi

# Install Firefox plugins
if ask_permission "install Firefox plugins"; then
    echo "Installing Firefox plugins..."
    dnf install -y gstreamer1-plugin-openh264 mozilla-openh264
    echo "Firefox plugins installed."
fi

# Install Git and all related tools
if ask_permission "install Git and related tools"; then
    echo "Installing Git and related tools..."
    dnf install -y git-all
    echo "Git and related tools installed."
fi

# Install Neovim
if ask_permission "install Neovim"; then
    echo "Installing Neovim..."
    dnf install -y neovim
    echo "Neovim installed."
fi

# Install CMake
if ask_permission "install CMake"; then
    echo "Installing CMake..."
    dnf install -y cmake
    echo "CMake installed."
fi

# Ensure Flathub repository is added
if ask_permission "add Flathub repository"; then
    echo "Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo "Flathub repository added."
fi

# Update Flatpak repositories
if ask_permission "update Flatpak repositories"; then
    echo "Updating Flatpak repositories..."
    flatpak update -y
    echo "Flatpak repositories updated."
fi

# Install WezTerm via Flatpak
if ask_permission "install WezTerm via Flatpak"; then
    echo "Installing WezTerm via Flatpak..."
    flatpak install -y flathub org.wezfurlong.wezterm
    echo "WezTerm installed via Flatpak."
fi

# Install tmux
if ask_permission "install tmux"; then
    echo "Installing tmux..."
    dnf install -y tmux
    echo "tmux installed."
fi

# Install zellij
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

if ask_permission "install Zellij"; then
    install_zellij
fi

# Install Molten / luarocks dependencies
if ask_permission "install Molten/luarocks dependencies"; then
    echo "Installing Molten/luarocks dependencies..."
    dnf install -y compat-lua-devel-5.1.5 ImageMagick-devel
    echo "Molten/luarocks dependencies installed."
fi

# Install Go
if ask_permission "install Go"; then
    echo "Installing Go..."
    dnf install -y golang
    echo "Go installed."
fi

# Install Docker
if ask_permission "install Docker"; then
    echo "Installing Docker..."
    dnf install -y dnf-plugins-core
    dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl start docker
    groupadd docker
    echo "Docker installed and started."
fi

# Install ueberzugpp
if ask_permission "install ueberzugpp"; then
    echo "Installing ueberzugpp..."
    dnf config-manager --add-repo https://download.opensuse.org/repositories/home:justkidding/Fedora_40/home:justkidding.repo
    dnf install -y ueberzugpp
    echo "ueberzugpp installed."
fi

# Prompt for the target username
read -p "Enter the username for which you want to set up aliases: " target_user

if id "$target_user" &>/dev/null; then
    user_home=$(eval echo ~$target_user)
    bashrc="$user_home/.bashrc"
    bashrc_d="$user_home/.bashrc.d"
    aliases_file="$bashrc_d/aliases"
    profile="$user_home/.profile"
    bash_profile="$user_home/.bash_profile"

    # Add user to Docker group
    if ask_permission "add $target_user to the docker group"; then
        echo "Adding $target_user to the docker group..."
        gpasswd -a $target_user docker
        echo "$target_user added to the docker group."
    fi

    # Create .bashrc.d directory if it doesn't exist
    if [ ! -d "$bashrc_d" ]; then
        echo "Creating $bashrc_d directory..."
        mkdir -p "$bashrc_d"
        chown $target_user:$target_user "$bashrc_d"
        chmod 755 "$bashrc_d"
        echo "$bashrc_d directory created."
    fi

    # Create or append to the aliases file
    touch "$aliases_file"

    # Function to add alias if it doesn't exist
    add_alias() {
        local alias_name="$1"
        local alias_command="$2"
        echo "Adding/Updating alias for $alias_name..."
        sed -i "/alias $alias_name=/d" "$aliases_file"
        echo "alias $alias_name='$alias_command'" >> "$aliases_file"
        echo "Added/Updated alias for $alias_name"
    }

    # Add aliases
    add_alias "wezterm" "flatpak run org.wezfurlong.wezterm"
    add_alias "vim" "nvim"

    # Ensure XDG_DATA_DIRS includes Flatpak applications
    echo "Updating XDG_DATA_DIRS..."
    update_file_content "$aliases_file" "XDG_DATA_DIRS.*flatpak" '
# Flatpak directories in XDG_DATA_DIRS
export XDG_DATA_DIRS="$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share"
'

    # Set up Go environment for the target user
    echo "Setting up Go environment for $target_user..."
    sudo -u $target_user mkdir -p $user_home/go
    update_file_content "$bashrc" "export GOPATH=" '
# Go environment setup
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
'

    # Set up Python virtual environment functionality
    echo "Setting up Python virtual environment functionality..."
    venv_file="$user_home/.venv_functions"
    venv_config="
# Python virtual environment setup
export VENV_HOME=\"$user_home/.virtualenvs\"
[[ -d \$VENV_HOME ]] || mkdir \$VENV_HOME

lsvenv() {
  ls -1 \$VENV_HOME
}

venv() {
  if [ \$# -eq 0 ]; then
    echo \"Please provide venv name\"
  else
    source \"\$VENV_HOME/\$1/bin/activate\"
  fi
}

mkvenv() {
  if [ \$# -eq 0 ]; then
    echo \"Please provide venv name\"
  else
    python3 -m venv \$VENV_HOME/\$1
  fi
}

rmvenv() {
  if [ \$# -eq 0 ]; then
    echo \"Please provide venv name\"
  else
    rm -r \$VENV_HOME/\$1
  fi
}
"

    # Create or update the .venv_functions file
    echo "$venv_config" > "$venv_file"
    chown $target_user:$target_user "$venv_file"
    chmod 644 "$venv_file"
    echo "Created/Updated $venv_file"

    # Source the .venv_functions file in .bashrc
    echo "Updating $bashrc to source $venv_file..."
    update_file_content "$bashrc" "Source venv functions" "
# Source venv functions
if [ -f $venv_file ]; then
    . $venv_file
fi
"
    echo "Updated $bashrc to source $venv_file"

    # Add venv functions directly to .bashrc as a fallback
    echo "Adding venv functions directly to $bashrc..."
    echo "$venv_config" >> "$bashrc"
    echo "Added venv functions directly to $bashrc"

    # Ensure .bash_profile exists and sources .bashrc
    if [ ! -f "$bash_profile" ]; then
        echo "Creating $bash_profile..."
        touch "$bash_profile"
        chown $target_user:$target_user "$bash_profile"
        echo "$bash_profile created."
    fi

    echo "Updating $bash_profile to source $bashrc..."
    update_file_content "$bash_profile" "Source .bashrc" "
# Source .bashrc if it exists
if [ -f $bashrc ]; then
    . $bashrc
fi
"
    echo "Updated $bash_profile to source $bashrc"

    # Create .virtualenvs directory
    echo "Creating $user_home/.virtualenvs directory..."
    sudo -u $target_user mkdir -p $user_home/.virtualenvs
    echo "Created $user_home/.virtualenvs directory"

    # Ensure the aliases file has the correct permissions
    echo "Setting permissions for $aliases_file..."
    chown $target_user:$target_user "$aliases_file"
    chmod 644 "$aliases_file"
    echo "Permissions set for $aliases_file"

    # Modify .bashrc to source files in .bashrc.d
    echo "Updating $bashrc to source files in .bashrc.d..."
    update_file_content "$bashrc" "Source user-specific configuration files" '
# Source user-specific configuration files
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
'

    # Ensure .profile sources .bashrc
    echo "Updating $profile to source $bashrc..."
    update_file_content "$profile" "Source .bashrc" '
# Source .bashrc if it exists
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
'

    echo "Aliases, XDG_DATA_DIRS updates, and Go environment added for $target_user."
    echo ".bashrc has been updated to source files in .bashrc.d"
    echo ".profile and .bash_profile have been updated to source .bashrc and .venv_functions"

    # Install tmux plugin manager for the target user
    tpm_dir="$user_home/.tmux/plugins/tpm"
    if [ ! -d "$tpm_dir" ]; then
        if ask_permission "install tmux plugin manager for $target_user"; then
            echo "Installing tmux plugin manager for $target_user..."
            sudo -u $target_user git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
            echo "tmux plugin manager installed for $target_user."
        fi
    else
        echo "tmux plugin manager directory already exists. Skipping installation."
    fi

else
    echo "User $target_user does not exist. Please check the username and try again."
    exit 1
fi

if ask_permission "setup plasma configuration"; then
    echo "Setting up plasma configuration..."
    
    # Copy panel configuration using relative paths
    sudo -u $target_user cp -r "./plasma-config/plasma-"* "$user_home/.config/"
    
    # Setup toggle script
    sudo -u $target_user mkdir -p "$user_home/.local/bin"
    sudo -u $target_user cp "./plasma-config/scripts/toggle-plasma-panel.sh" \
        "$user_home/.local/bin/toggle-plasma-panel"
    chmod +x "$user_home/.local/bin/toggle-plasma-panel"
    
    # Configure shortcuts without kglobalaccel
    if [ -n "$(pgrep -u $target_user plasma)" ]; then
        echo "Stopping Plasma..."
        sudo -u $target_user kquitapp5 plasmashell || true
        sleep 2
    fi
    
    # Configure shortcut files
    sudo -u $target_user mkdir -p "$user_home/.config"
    
    sudo -u $target_user tee "$user_home/.config/kglobalshortcutsrc" > /dev/null << 'EOL'
[plasmashell]
_launch=none,none,none
activate application launcher=none,none,none
show dashboard=none,none,none

[kwin]
ShowDesktopGrid=none,none,none
EOF
EOL

    sudo -u $target_user tee "$user_home/.config/khotkeysrc" > /dev/null << EOL
[Data]
DataCount=1

[Data_1]
Comment=Toggle Panel and Launcher
Enabled=true
Name=Toggle Panel and Launcher
Type=SIMPLE_ACTION_DATA

[Data_1_1]
Type=COMMAND_URL

[Data_1_1Actions]
CommandURL=$user_home/.local/bin/toggle-plasma-panel

[Data_1_1Triggers]
Key=Meta
Type=SHORTCUT
EOL

    # Start Plasma again
    echo "Starting Plasma..."
    sudo -u $target_user XDG_RUNTIME_DIR=/run/user/$(id -u $target_user) DISPLAY=:0 plasmashell > /dev/null 2>&1 &
    
    echo "Plasma configuration complete. The changes will take effect after logging out and back in."
fi

echo "Setup complete!"

# Final instructions
echo "
Setup process has been completed. Here are some final steps and reminders:

1. Log out and log back in to ensure all changes take effect.
2. Run the ueberzugpp test script: ./dotfiles/fedora/test_ueberzugpp.sh
3. If you encounter any issues with ueberzugpp, try the following troubleshooting steps:
   a. Check system logs: journalctl -xe | grep ueberzugpp
   b. Run ueberzugpp with debug output: ueberzugpp layer --parser json -v <<< '{\"action\": \"add\", \"identifier\": \"test\", \"x\": 0, \"y\": 0, \"path\": \"/path/to/image.png\"}'
   c. Check for conflicting processes: ps aux | grep ueberzugpp
4. Make sure to review and customize your Neovim configuration as needed.
5. If you installed Docker, you may need to start the service: sudo systemctl start docker
6. For Go development, remember that your GOPATH is set to $HOME/go
7. Python virtual environments can be managed using the venv, mkvenv, and rmvenv functions.
8. If you installed tmux plugin manager, open tmux and press prefix + I to install plugins.

If you encounter any issues or need further assistance, please refer to the respective documentation for each installed tool.

Enjoy your newly set up system!
"
