#!/bin/bash

# Check if we're in the right directory
if [[ ! -d "plasma-config" ]]; then
    echo "Error: This script must be run from the fedora directory containing plasma-config/"
    exit 1
fi

# Function to backup a file if it exists and is different
backup_if_changed() {
    local source="$1"
    local dest="$2"
    
    if [[ -f "$source" ]]; then
        if [[ ! -f "$dest" ]] || ! cmp --silent "$source" "$dest"; then
            echo "Backing up $source to $dest"
            cp "$source" "$dest"
            return 0
        else
            echo "No changes in $source"
            return 1
        fi
    else
        echo "Warning: Source file $source does not exist"
        return 2
    fi
}

# Backup main Plasma configuration files
echo "Backing up Plasma configuration files..."

# Ensure black wallpaper settings before backup
for containment in $(kreadconfig5 --file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" \
    --group "Containments" --list | grep "\[.*\]"); do
    if [[ $(kreadconfig5 --file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" \
        --group "Containments${containment}" --key "plugin") == "org.kde.plasma.folder" ]]; then
        kwriteconfig5 --file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" \
            --group "Containments${containment}[Wallpaper][org.kde.color][General]" \
            --key "Color" "#000000"
        
        kwriteconfig5 --file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" \
            --group "Containments${containment}" \
            --key "wallpaperplugin" "org.kde.color"
    fi
done

# Backup plasma-org.kde.plasma.desktop-appletsrc
backup_if_changed "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" "plasma-config/plasma-org.kde.plasma.desktop-appletsrc"

# Backup plasmashellrc
backup_if_changed "$HOME/.config/plasmashellrc" "plasma-config/plasmashellrc"

# Backup plasma panel toggle script
if [[ -f "$HOME/.local/bin/toggle-plasma-panel" ]]; then
    echo "Backing up toggle-plasma-panel script..."
    mkdir -p "plasma-config/scripts"
    backup_if_changed "$HOME/.local/bin/toggle-plasma-panel" "plasma-config/scripts/toggle-plasma-panel.sh"
    chmod +x "plasma-config/scripts/toggle-plasma-panel.sh"
fi

# Backup shortcut configuration
if [[ -f "$HOME/.config/khotkeysrc" ]]; then
    echo "Generating shortcut configuration script..."
    cat > "plasma-config/scripts/configure-shortcut.sh" << 'EOL'
#!/bin/bash

# Configure shortcut for toggle-plasma-panel
kwriteconfig5 --file "$HOME/.config/khotkeysrc" \
    --group "Data" --key "DataCount" "1"

kwriteconfig5 --file "$HOME/.config/khotkeysrc" \
    --group "Data_1" --key "Comment" "Toggle Panel and Launcher" \
    --group "Data_1" --key "Enabled" "true" \
    --group "Data_1" --key "Name" "Toggle Panel and Launcher" \
    --group "Data_1" --key "Type" "SIMPLE_ACTION_DATA"

kwriteconfig5 --file "$HOME/.config/khotkeysrc" \
    --group "Data_1_1" --key "Type" "COMMAND_URL"

kwriteconfig5 --file "$HOME/.config/khotkeysrc" \
    --group "Data_1_1Actions" --key "CommandURL" "$HOME/.local/bin/toggle-plasma-panel"

kwriteconfig5 --file "$HOME/.config/khotkeysrc" \
    --group "Data_1_1Triggers" --key "Key" "Meta" \
    --group "Data_1_1Triggers" --key "Type" "SHORTCUT"

# Remove conflicting Meta shortcuts
kwriteconfig5 --file "$HOME/.config/kglobalshortcutsrc" \
    --group "plasmashell" --key "_launch" "none,none,none"
kwriteconfig5 --file "$HOME/.config/kglobalshortcutsrc" \
    --group "plasmashell" --key "activate application launcher" "none,none,none"

# Reload configurations
qdbus org.kde.kglobalaccel /kglobalaccel org.kde.kglobalaccel.reloadConfig
EOL
    chmod +x "plasma-config/scripts/configure-shortcut.sh"
    echo "Created configure-shortcut.sh script"
fi

# Create a Git commit if we're in a Git repository
if git rev-parse --git-dir > /dev/null 2>&1; then
    if git status --porcelain | grep -q '^'; then
        echo "Changes detected, creating commit..."
        git add plasma-config/
        git commit -m "Update Plasma configuration $(date +%Y-%m-%d)"
        echo "Committed changes to repository"
    else
        echo "No changes to commit"
    fi
else
    echo "Not a Git repository, skipping commit"
fi

echo "Backup complete!"
