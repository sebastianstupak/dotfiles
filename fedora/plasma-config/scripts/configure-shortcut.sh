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
