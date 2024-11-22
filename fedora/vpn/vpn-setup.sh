#!/bin/bash
set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Make all script components executable
chmod +x "$(dirname "$0")/scripts/"*.sh
chmod +x "$(dirname "$0")/config/"*.sh

# Source required files
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/config/countries.sh"

echo -e "${BLUE}ProtonVPN WireGuard Setup${NC}"

# Check for root/sudo availability
if ! command -v sudo &> /dev/null; then
    echo -e "${RED}Error: sudo is required but not installed${NC}"
    exit 1
fi

# Check for existing configurations
mapfile -t EXISTING_CONFIGS < <(sudo find /etc/wireguard -name "*.conf" -type f 2>/dev/null || true)
IMPORT_NEW=true

if [ ${#EXISTING_CONFIGS[@]} -gt 0 ]; then
    echo -e "\n${BLUE}Found existing WireGuard configurations:${NC}"
    for conf in "${EXISTING_CONFIGS[@]}"; do
        basename=$(basename "$conf")
        echo -e "${GREEN}$basename${NC}"
    done
    
    echo -e "\n${YELLOW}Would you like to:"
    echo "1) Use existing configurations only"
    echo "2) Import additional configurations"
    echo -e "Choose [1/2]:${NC}"
    read -r choice
    
    case $choice in
        1)
            echo -e "${GREEN}Using existing configurations.${NC}"
            IMPORT_NEW=false
            ;;
        2)
            echo -e "${GREEN}Will import additional configurations.${NC}"
            IMPORT_NEW=true
            ;;
        *)
            echo -e "${RED}Invalid choice. Using existing configurations.${NC}"
            IMPORT_NEW=false
            ;;
    esac
fi

if [ "$IMPORT_NEW" = true ]; then
    echo -e "\n${YELLOW}Instructions:${NC}"
    echo "1. Visit https://account.protonvpn.com/downloads"
    echo "2. Log in to your ProtonVPN account"
    echo "3. Download WireGuard configurations for your preferred servers"
    echo "4. Save them to your Downloads folder"
    echo "5. Return here to continue setup"

    read -p "Press enter when you have downloaded the configuration files..."

    mapfile -t CONF_FILES < <(find "$HOME/Downloads" -maxdepth 1 -name "*.conf" -type f | sort)
    if [ ${#CONF_FILES[@]} -eq 0 ]; then
        if [ ${#EXISTING_CONFIGS[@]} -eq 0 ]; then
            echo -e "${RED}No .conf files found in Downloads folder and no existing configurations!${NC}"
            exit 1
        else
            echo -e "${YELLOW}No new configurations found in Downloads. Using existing ones.${NC}"
            IMPORT_NEW=false
        fi
    fi
fi

if [ "$IMPORT_NEW" = true ] && [ ${#CONF_FILES[@]} -gt 0 ]; then
    echo -e "\n${BLUE}Found Configuration Files:${NC}"
    for conf in "${CONF_FILES[@]}"; do
        basename=$(basename "$conf")
        if [[ "$basename" =~ ^([A-Z]{2})-([A-Z]{2})?#?[0-9]+\.conf$ ]]; then
            country="${BASH_REMATCH[1]}"
            exit_country="${BASH_REMATCH[2]:-$country}"
            if [[ -n "${COUNTRY_INFO[$exit_country]}" ]]; then
                echo -e "${GREEN}$basename${NC} - ${COUNTRY_INFO[$exit_country]}"
            else
                echo -e "${GREEN}$basename${NC}"
            fi
        else
            echo -e "${GREEN}$basename${NC}"
        fi
    done

    declare -a selected
    for ((i=0; i<${#CONF_FILES[@]}; i++)); do
        selected[$i]=false
    done

    # Selection menu logic
    while true; do
        echo -e "\n${BLUE}Available configurations:${NC}"
        for ((i=0; i<${#CONF_FILES[@]}; i++)); do
            basename=$(basename "${CONF_FILES[$i]}")
            mark=${selected[$i]} && [[ "$mark" == "true" ]] && mark="[*]" || mark="[ ]"
            echo -e "$((i+1))) $mark ${GREEN}$basename${NC}"
        done

        echo -e "\n${BLUE}Commands:${NC}"
        echo "Enter number to toggle selection"
        echo "a - Select all"
        echo "n - Select none"
        echo "d - Done"
        echo "q - Quit"
        read -p "Enter command: " choice

        case $choice in
            [0-9]*)
                if [ "$choice" -ge 1 ] && [ "$choice" -le ${#CONF_FILES[@]} ]; then
                    selected[$((choice-1))]=$([ "${selected[$((choice-1))]}" == "true" ] && echo "false" || echo "true")
                else
                    echo -e "${RED}Invalid selection${NC}"
                fi
                ;;
            a|A)
                for ((i=0; i<${#CONF_FILES[@]}; i++)); do
                    selected[$i]=true
                done
                ;;
            n|N)
                for ((i=0; i<${#CONF_FILES[@]}; i++)); do
                    selected[$i]=false
                done
                ;;
            d|D)
                any_selected=false
                for ((i=0; i<${#CONF_FILES[@]}; i++)); do
                    [[ "${selected[$i]}" == "true" ]] && any_selected=true
                done
                if [ "$any_selected" = true ]; then
                    break
                else
                    echo -e "${RED}Please select at least one configuration${NC}"
                fi
                ;;
            q|Q)
                echo -e "${YELLOW}Operation cancelled${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid command${NC}"
                ;;
        esac
    done

    # Process selected configurations
    declare -a copied_files
    for ((i=0; i<${#CONF_FILES[@]}; i++)); do
        if [ "${selected[$i]}" = "true" ]; then
            source_config="${CONF_FILES[$i]}"
            basename=$(basename "$source_config")
            target_config="/etc/wireguard/$basename"
            echo -e "\n${BLUE}Setting up: $basename${NC}"
            sudo cp "$source_config" "$target_config"
            sudo chmod 600 "$target_config"
            copied_files+=("$source_config")
            echo -e "${GREEN}Installed: $basename${NC}"
        fi
    done

    if [ ${#copied_files[@]} -gt 0 ]; then
        echo -e "\n${YELLOW}Delete original files from Downloads? [y/N]${NC}"
        read -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for config in "${copied_files[@]}"; do
                rm -f "$config"
                echo "Deleted: $(basename "$config")"
            done
        fi
    fi
fi

# Install required packages
echo -e "\n${BLUE}Installing required packages...${NC}"
sudo dnf install -y wireguard-tools firewalld

# Enable and start firewalld
sudo systemctl enable --now firewalld

# Configure IPv6
source "$SCRIPT_DIR/scripts/ipv6_setup.sh"

# Set up aliases
mkdir -p "$HOME/.config/protonvpn"
cp "$SCRIPT_DIR/config/aliases.sh" "$HOME/.config/protonvpn/wg_aliases"

# Add source line to shell config if not already present
for RC_FILE in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$RC_FILE" ]; then
        if ! grep -q "source ~/.config/protonvpn/wg_aliases" "$RC_FILE"; then
            echo -e "\nsource ~/.config/protonvpn/wg_aliases" >> "$RC_FILE"
            echo -e "${GREEN}Added aliases to $RC_FILE${NC}"
        fi
    fi
done

echo -e "\n${GREEN}Setup complete! Available commands:${NC}"
echo "vpn                 - Show help and available commands"
echo "vpn up [config]     - Connect to VPN"
echo "vpn down [config]   - Disconnect from VPN"
echo "vpn switch [config] - Switch to different config"
echo "vpn status         - Show VPN status"
echo "vpn list           - List available configurations"
echo "vpn menu           - Interactive menu"
echo "vpn ip             - Show current IP"
echo "vpn test           - Test for IP and DNS leaks"

echo -e "\n${BLUE}To start using the commands, run:${NC}"
echo -e "${GREEN}source ~/.config/protonvpn/wg_aliases${NC}"
