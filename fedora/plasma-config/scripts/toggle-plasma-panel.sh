#!/bin/bash

# Toggle panel visibility
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
    var allPanels = panels();
    for (var i = 0; i < allPanels.length; i++) {
        if (allPanels[i].location === "top") {
            var panel = allPanels[i];
            panel.height = (panel.height > 0) ? 0 : 20;
            break;
        }
    }
'

# Show application launcher
qdbus org.kde.plasmashell /PlasmaShell evaluateScript '
    const launcher = panels()[1].widgets().filter(w => w.type === "org.kde.plasma.kickoff")[0];
    if (launcher) launcher.clicked();
'
