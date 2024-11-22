#!/bin/bash

# Function for logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$HOME/ueberzugpp_test.log"
}

# Start logging
log "Starting ueberzugpp test script"

# Check if ueberzugpp is installed
if ! command -v ueberzugpp &> /dev/null; then
    log "ERROR: ueberzugpp is not installed or not in PATH"
    exit 1
fi

# Log system information
log "System information:"
log "$(uname -a)"

# Log terminal information
log "Terminal information:"
log "TERM=$TERM"
log "SHELL=$SHELL"
log "DISPLAY=$DISPLAY"
log "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
log "XDG_SESSION_TYPE=$XDG_SESSION_TYPE"
log "Terminal emulator: $TERM_PROGRAM"

# Log ueberzugpp version
log "ueberzugpp version:"
ueberzugpp_version=$(ueberzugpp --version 2>&1)
log "$ueberzugpp_version"

# Function to get terminal size
get_terminal_size() {
    if [ -n "$LINES" ] && [ -n "$COLUMNS" ]; then
        echo "$LINES $COLUMNS"
    elif command -v tput > /dev/null 2>&1; then
        echo "$(tput lines) $(tput cols)"
    elif command -v stty > /dev/null 2>&1; then
        stty size
    else
        echo "24 80"  # fallback to a common default
    fi
}

# Get terminal size
read LINES COLUMNS < <(get_terminal_size)
log "Terminal size: ${COLUMNS}x${LINES}"

# Function to run ueberzugpp with error handling
run_ueberzugpp() {
    local command="$1"
    local description="$2"
    local options="$3"
    
    log "Running: $description"
    output=$(echo "$command" | TERM=xterm-256color ueberzugpp layer $options 2>&1)
    exit_code=$?
    
    log "Command: TERM=xterm-256color echo '$command' | ueberzugpp layer $options"
    log "Exit code: $exit_code"
    log "Output: $output"
    
    if [ $exit_code -ne 0 ]; then
        log "ERROR: ueberzugpp exited with non-zero status ($exit_code)"
        return 1
    else
        log "Success: $description"
    fi
}

# Find a KDE Plasma wallpaper
kde_wallpaper="/usr/share/wallpapers/Next/contents/images/1920x1080.jpg"
if [ ! -f "$kde_wallpaper" ]; then
    kde_wallpaper=$(find /usr/share/wallpapers -name "*.jpg" | head -n 1)
fi

if [ -z "$kde_wallpaper" ]; then
    log "ERROR: Could not find a KDE Plasma wallpaper"
    exit 1
fi

log "Using wallpaper: $kde_wallpaper"

# Test with different output methods
for method in x11 wayland sixel kitty iterm2 chafa; do
    log "Testing with output method: $method"
    run_ueberzugpp '{"action":"add","identifier":"test","max_height":'$LINES',"max_width":'$COLUMNS',"path":"'$kde_wallpaper'","x":0,"y":0}' "Add image ($method)" "--output $method"
    sleep 2
    run_ueberzugpp '{"action":"remove","identifier":"test"}' "Remove test image ($method)" "--output $method"
done

# Test with default options
log "Testing with default options"
run_ueberzugpp '{"action":"add","identifier":"test","max_height":'$LINES',"max_width":'$COLUMNS',"path":"'$kde_wallpaper'","x":0,"y":0}' "Add image (default)" ""
sleep 2
run_ueberzugpp '{"action":"remove","identifier":"test"}' "Remove test image (default)" ""

# Log final status
log "All tests completed."
log "Please check $HOME/ueberzugpp_test.log for detailed output."

echo "Test script execution complete. See $HOME/ueberzugpp_test.log for details."
