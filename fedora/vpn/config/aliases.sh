#!/bin/bash

# Helper function to test connection
test_connection() {
    local max_attempts=3
    local timeout=5
    local success=false

    echo "Testing internet connection..."
    for ((i=1; i<=max_attempts; i++)); do
        if curl -s --connect-timeout $timeout https://api.ipify.org &>/dev/null; then
            success=true
            break
        fi
        echo "Attempt $i failed, waiting before retry..."
        sleep 2
    done

    if $success; then
        echo "Connection test successful"
        return 0
    else
        echo "Connection test failed"
        return 1
    fi
}

# Helper function to extract VPN endpoints from WireGuard config
get_endpoints() {
    local config_file="$1"
    # Extract Endpoint from WireGuard config, get only the IP/hostname part
    grep '^Endpoint' "$config_file" | cut -d '=' -f2 | cut -d ':' -f1 | tr -d ' '
}

# Helper function to add endpoint rules
add_endpoint_rules() {
    local endpoint="$1"
    sudo iptables -A KILLSWITCH -d "$endpoint" -p udp -j ACCEPT
    # Also allow TCP for potential fallback/management
    sudo iptables -A KILLSWITCH -d "$endpoint" -p tcp -j ACCEPT
}

vpn() {
    case "$1" in
        "up"|"connect")
            if [ -z "$2" ]; then
                vpn menu
            else
                # Before connecting, ensure endpoints are allowed if kill switch is on
                if sudo iptables -L KILLSWITCH &>/dev/null; then
                    local endpoints=$(get_endpoints "/etc/wireguard/$2.conf")
                    for endpoint in $endpoints; do
                        add_endpoint_rules "$endpoint"
                    done
                fi
                
                sudo wg-quick up "$2"
                test_connection
            fi
            ;;
        "down"|"disconnect")
            if [ -z "$2" ]; then
                local current=$(sudo wg show interfaces)
                if [ -n "$current" ]; then
                    sudo wg-quick down "$current"
                else
                    echo "No active VPN connection"
                fi
            else
                sudo wg-quick down "$2"
            fi
            ;;
        "status")
            echo -e "Active connections:"
            sudo wg show all || echo "No active connections"
            echo -e "\nFirewall status:"
            if sudo iptables -L KILLSWITCH &>/dev/null; then
                echo "Kill switch is ENABLED"
                echo -e "\nKill switch rules:"
                sudo iptables -L KILLSWITCH -v -n
            else
                echo "Kill switch is DISABLED"
            fi
            echo -e "\nConnection test:"
            test_connection
            echo -e "\nCurrent IP:"
            curl -s https://api.ipify.org || echo "Failed to get IP"
            ;;
        "list")
            echo "Available configurations:"
            sudo find /etc/wireguard -name "*.conf" -exec basename {} .conf \;
            ;;
        "ip")
            echo -e "Current IP addresses:"
            echo -e "\nIPv4:"
            curl -4 -s https://api.ipify.org
            echo -e "\nIPv6 (should fail if disabled):"
            curl -6 --connect-timeout 5 icanhazip.com || echo "IPv6 is disabled (good)"
            ;;
        "kill")
            case "$2" in
                "enable"|"on")
                    echo "Enabling kill switch..."
                    
                    # Clean up any existing rules
                    vpn kill disable &>/dev/null || true
                    
                    # Create killswitch chain
                    sudo iptables -N KILLSWITCH 2>/dev/null || true
                    sudo iptables -F KILLSWITCH
                    
                    echo "Adding basic rules..."
                    # Allow established/related connections first
                    sudo iptables -A KILLSWITCH -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
                    # Allow loopback
                    sudo iptables -A KILLSWITCH -o lo -j ACCEPT
                    
                    # Allow DNS (both UDP and TCP)
                    sudo iptables -A KILLSWITCH -p udp --dport 53 -j ACCEPT
                    sudo iptables -A KILLSWITCH -p tcp --dport 53 -j ACCEPT
                    
                    echo "Adding VPN endpoints..."
                    # Add rules for all VPN endpoints in all configs
                    for conf in /etc/wireguard/*.conf; do
                        if [ -f "$conf" ]; then
                            local endpoints=$(get_endpoints "$conf")
                            for endpoint in $endpoints; do
                                echo "Adding rules for endpoint: $endpoint"
                                add_endpoint_rules "$endpoint"
                            done
                        fi
                    done
                    
                    # Allow WireGuard interface traffic
                    sudo iptables -A KILLSWITCH -o wg+ -j ACCEPT
                    
                    # Drop all other traffic
                    sudo iptables -A KILLSWITCH -j DROP
                    
                    # Add to OUTPUT chain if not already there
                    sudo iptables -C OUTPUT -j KILLSWITCH 2>/dev/null || \
                        sudo iptables -I OUTPUT 1 -j KILLSWITCH
                    
                    echo "Testing connection..."
                    if test_connection; then
                        echo "Kill switch enabled and connection working"
                    else
                        echo "Warning: Connection test failed. Checking active VPN..."
                        local current=$(sudo wg show interfaces)
                        if [ -n "$current" ]; then
                            echo "VPN is active, rechecking endpoints..."
                            local endpoints=$(get_endpoints "/etc/wireguard/$current.conf")
                            for endpoint in $endpoints; do
                                add_endpoint_rules "$endpoint"
                            done
                            test_connection
                        else
                            echo "No active VPN connection. Connect to VPN with: vpn up <config>"
                        fi
                    fi
                    ;;
                "disable"|"off")
                    echo "Disabling kill switch..."
                    # Remove from OUTPUT chain
                    sudo iptables -D OUTPUT -j KILLSWITCH 2>/dev/null || true
                    # Flush and remove chain
                    sudo iptables -F KILLSWITCH 2>/dev/null || true
                    sudo iptables -X KILLSWITCH 2>/dev/null || true
                    echo "Kill switch disabled"
                    ;;
                "status")
                    if sudo iptables -L KILLSWITCH &>/dev/null; then
                        echo "Kill switch is currently ENABLED"
                        echo -e "\nActive rules:"
                        sudo iptables -L KILLSWITCH -v -n
                    else
                        echo "Kill switch is currently DISABLED"
                    fi
                    test_connection
                    ;;
                "test")
                    echo "Testing kill switch..."
                    local current=$(sudo wg show interfaces)
                    if [ -n "$current" ]; then
                        echo "1. Current VPN connection: $current"
                        echo "2. Testing connection with VPN..."
                        if test_connection; then
                            echo "VPN connection working"
                            
                            echo "3. Testing kill switch by disconnecting VPN..."
                            sudo wg-quick down "$current"
                            sleep 2
                            if curl -s --connect-timeout 5 https://api.ipify.org &>/dev/null; then
                                echo "WARNING: Internet still accessible without VPN!"
                                echo "Kill switch might not be working properly."
                            else
                                echo "Success: Internet blocked without VPN"
                                echo "Kill switch is working properly"
                            fi
                            
                            echo "4. Restoring VPN connection..."
                            sudo wg-quick up "$current"
                            sleep 2
                            test_connection
                        else
                            echo "Warning: Connection not working with VPN"
                        fi
                    else
                        echo "No active VPN connection to test with"
                        echo "Please connect to VPN first with: vpn up <config>"
                    fi
                    ;;
                *)
                    echo "Kill switch usage:"
                    echo "  vpn kill enable  - Enable kill switch"
                    echo "  vpn kill disable - Disable kill switch"
                    echo "  vpn kill status  - Show kill switch status"
                    echo "  vpn kill test    - Test kill switch functionality"
                    ;;
            esac
            ;;
        "test")
            echo -e "Running VPN leak tests...\n"
            echo -e "1. Testing VPN connection:"
            test_connection
            
            if [ $? -eq 0 ]; then
                echo -e "\n2. Testing current IP:"
                echo -n "IPv4: "
                curl -4 -s https://api.ipify.org || echo "Failed to get IPv4"
                
                echo -e "\n3. Testing IPv6 (should fail):"
                if curl -6 --connect-timeout 5 icanhazip.com 2>/dev/null; then
                    echo "WARNING: IPv6 is enabled and might leak!"
                else
                    echo "IPv6 is properly disabled"
                fi
            else
                echo "Connection test failed, skipping IP tests"
            fi
            
            echo -e "\n4. Testing DNS leaks:"
            echo "DNS Servers in use:"
            cat /etc/resolv.conf | grep nameserver
            
            echo -e "\n5. Testing Kill Switch:"
            if sudo iptables -L KILLSWITCH &>/dev/null; then
                echo "Kill switch is ENABLED"
                echo -e "\nKill switch rules:"
                sudo iptables -L KILLSWITCH -v -n
            else
                echo "Kill switch is DISABLED"
            fi
            
            echo -e "\n6. Active WireGuard Connections:"
            sudo wg show all || echo "No active connections"
            ;;
        "switch"|"menu")
            local configs=($(sudo find /etc/wireguard -name "*.conf" -exec basename {} .conf \;))
            if [ ${#configs[@]} -eq 0 ]; then
                echo "No VPN configurations found"
                return 1
            fi
            
            echo "Available VPN configurations:"
            for i in "${!configs[@]}"; do
                current=""
                if sudo wg show interfaces | grep -q "^${configs[i]}$"; then
                    current=" (ACTIVE)"
                fi
                echo "$((i+1))) ${configs[i]}$current"
            done
            
            read -p "Select configuration number (or 0 to cancel): " choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -gt 0 ] && [ "$choice" -le ${#configs[@]} ]; then
                local selected_config="${configs[$((choice-1))]}"
                # First disconnect any active connection
                local current=$(sudo wg show interfaces)
                if [ -n "$current" ]; then
                    echo "Disconnecting from $current..."
                    sudo wg-quick down "$current"
                fi
                # Connect to the selected config
                echo "Connecting to $selected_config..."
                
                # If kill switch is enabled, ensure the endpoints are allowed
                if sudo iptables -L KILLSWITCH &>/dev/null; then
                    local endpoints=$(get_endpoints "/etc/wireguard/$selected_config.conf")
                    for endpoint in $endpoints; do
                        add_endpoint_rules "$endpoint"
                    done
                fi
                
                sudo wg-quick up "$selected_config"
                sleep 2
                test_connection
            fi
            ;;
        "help"|*)
            echo "ProtonVPN WireGuard Commands:"
            echo "  vpn up [config]      - Connect to VPN"
            echo "  vpn down [config]    - Disconnect VPN"
            echo "  vpn switch [config]  - Switch to different VPN config"
            echo "  vpn status          - Show VPN and firewall status"
            echo "  vpn list            - List available configurations"
            echo "  vpn menu            - Interactive menu to select VPNs"
            echo "  vpn ip              - Show current IP address"
            echo "  vpn kill enable     - Enable kill switch"
            echo "  vpn kill disable    - Disable kill switch"
            echo "  vpn kill status     - Show kill switch status"
            echo "  vpn kill test       - Test kill switch functionality"
            echo "  vpn test            - Run all VPN tests"
            echo "  vpn help            - Show this help message"
            ;;
    esac
}

# Completion for vpn command
_vpn_completion() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    local prev=${COMP_WORDS[COMP_CWORD-1]}

    case "$prev" in
        "vpn")
            COMPREPLY=($(compgen -W "up down switch status list menu ip kill test help" -- "$cur"))
            ;;
        "up"|"down"|"switch")
            COMPREPLY=($(compgen -W "$(sudo find /etc/wireguard -name "*.conf" -exec basename {} .conf \;)" -- "$cur"))
            ;;
        "kill")
            COMPREPLY=($(compgen -W "enable disable status test" -- "$cur"))
            ;;
        *)
            COMPREPLY=()
            ;;
    esac
}

complete -F _vpn_completion vpn
