#!/bin/bash

# Remove any existing custom shortcuts
rm -f ~/.config/khotkeysrc

# Create new custom shortcut
cat > ~/.config/khotkeysrc << 'INNER'
[Data]
DataCount=1

[Data_1]
Comment=Custom Shortcuts
DataCount=1
Enabled=true
Name=Custom Shortcuts
SystemGroup=0
Type=ACTION_DATA_GROUP

[Data_1Conditions]
Comment=
ConditionsCount=0

[Data_1_1]
Comment=Toggle Panel and Launcher
Enabled=true
Name=Toggle Panel and Launcher
Type=SIMPLE_ACTION_DATA

[Data_1_1Actions]
ActionsCount=1
CommandURL=$HOME/.local/bin/toggle-plasma-panel
Type=COMMAND_URL

[Data_1_1Conditions]
Comment=
ConditionsCount=0

[Data_1_1Triggers]
Comment=Simple_action
TriggersCount=1
Trigger0=Meta
Trigger0Type=SHORTCUT
Trigger0Uuid={71665147-5bf5-4c2c-a561-cf19a2c6c426}
INNER

# Replace $HOME with actual home path
sed -i "s|\$HOME|$HOME|g" ~/.config/khotkeysrc

# Reload KDE configurations
qdbus org.kde.klauncher5 /KLauncher reparseConfiguration
qdbus org.kde.kglobalaccel /kglobalaccel org.kde.kglobalaccel.reloadConfig
