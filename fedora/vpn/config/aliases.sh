#!/bin/bash

vpn() {
    case "$1" in
        "up"|"connect")
            if [ -z "$2" ]; then
                vpn menu
            else
                sudo wg-quick up "$2"
                echo "Updating firewall rules for VPN..."
                sudo firewall-cmd --zone=public --add-masquerade
                sudo firewall-cmd --zone=public --add-port=51820/udp
            fi
            ;;
        "down"|"disconnect")
            if [ -z "$2" ]; then
                local current=$(sudo wg show interfaces)
                if [ -n "$current" ]; then
                    sudo wg-quick down "$current"
                    echo "Resetting firewall rules..."
                    sudo firewall-cmd --zone=public --remove-masquerade
                    sudo firewall-cmd --zone=public --remove-port=51820/udp
                else
                    echo "No active VPN connection"
                fi
            else
                sudo wg-quick down "$2"
                echo "Resetting firewall rules..."
                sudo firewall-cmd --zone=public --remove-masquerade
                sudo firewall-cmd --zone=public --remove-port=51820/udp
            fi
            ;;
        "status")
            echo -e "Active connections:"
            sudo wg show all || echo "No active connections"
            echo -e "\nFirewall status:"
            sudo firewall-cmd --list-all
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
        "test")
            echo -e "Running VPN leak tests...\n"
            echo -e "1. Testing IPv4:"
            echo -n "Current IPv4: "
            curl -4 -s https://api.ipify.org
            
            echo -e "\n\n2. Testing IPv6 (should fail):"
            if curl -6 --connect-timeout 5 icanhazip.com 2>/dev/null; then
                echo -e "WARNING: IPv6 is enabled and might leak!"
            else
                echo -e "IPv6 is properly disabled"
            fi
            
            echo -e "\n3. Testing DNS leaks:"
            echo "DNS Servers in use:"
            cat /etc/resolv.conf | grep nameserver
            
            echo -e "\n4. Testing Firewall Rules:"
            sudo firewall-cmd --list-all
            ;;
        "menu")
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
                vpn switch "${configs[choice-1]}"
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
            echo "  vpn test            - Run VPN leak tests"
            echo "  vpn help            - Show this help message"
            ;;
    esac
}
