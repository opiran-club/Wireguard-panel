#!/bin/bash

SCRIPT_DIR=$(dirname "$(realpath "$0")")

RED='\033[0;31m'
GREEN='\033[1;92m'
YELLOW='\033[1;33m'
BLUE='\033[96m'
CYAN='\033[0;36m'
NC='\033[0m' 
INFO="\033[96m"      
SUCCESS="\033[1;92m"    
WARNING="\e[33m"   
ERROR="\e[31m"      
RED="\e[31m"        

wireguard_detailed_stats() {
    echo -e "${CYAN}Wireguard Detailed Status:${NC}"
    echo -e "${YELLOW}═════════════════════════════════════════════════════════════════════${NC}"

    INTERFACE_FOUND=false
    for interface in /etc/wireguard/*.conf; do
        [ -e "$interface" ] || continue
        INTERFACE_FOUND=true

        INTERFACE_NAME=$(basename "$interface" .conf)

        IP_ADDRESS=$(grep '^Address' "$interface" | awk '{print $3}')
        PORT=$(grep '^ListenPort' "$interface" | awk '{print $3}')
        MTU=$(grep '^MTU' "$interface" | awk '{print $3}')
        DNS=$(grep '^DNS' "$interface" | awk '{print $3}')

        if wg show "$INTERFACE_NAME" >/dev/null 2>&1; then
            STATUS="Running"
            echo -e "${SUCCESS}Interface: ${CYAN}$INTERFACE_NAME${NC} ${SUCCESS}(Status: Running)${NC}"
        else
            STATUS="Inactive"
            echo -e "${WARNING}Interface: ${CYAN}$INTERFACE_NAME${NC} ${WARNING}(Status: Inactive)${NC}"
        fi

        echo -e "  ${GREEN}IP Address: ${CYAN}${IP_ADDRESS:-Not Assigned}${NC}"
        echo -e "  ${GREEN}Port: ${CYAN}${PORT:-Not Defined}${NC}"
        echo -e "  ${GREEN}MTU: ${CYAN}${MTU:-Default}${NC}"
        echo -e "  ${GREEN}DNS: ${CYAN}${DNS:-Not Set}${NC}"
        echo -e "${YELLOW}─────────────────────────────────────────────────────────────────────${NC}"
    done

    if [ "$INTERFACE_FOUND" = false ]; then
        echo -e "${ERROR}No Wireguard interfaces found! check your configuration.${NC}"
    else
        echo -e "${INFO}[INFO]${YELLOW}All interfaces have been checked.${NC}"
    fi

    echo -e "${YELLOW}═════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Press Enter to return to the menu...${NC}" && read
}


display_menu() {
    clear
    display_logo
    echo -e "${CYAN}╔═════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║      ${YELLOW}███████████████${NC}        ${BLUE}Main Menu${NC}        ${YELLOW}███████████████ ${CYAN}       ║${NC}"
    echo -e "${CYAN}╚═════════════════════════════════════════════════════════════════════╝${NC}"

    echo -e "${CYAN}╔═══════════════════════════ ${YELLOW}System Status${CYAN} ═══════════════════════════╗${NC}"

    INTERFACE_FOUND=false
    for interface in /etc/wireguard/*.conf; do
        [ -e "$interface" ] || continue
        INTERFACE_FOUND=true
        break
    done

    if [ "$INTERFACE_FOUND" = true ]; then
        echo -e "  ${GREEN}✔ Wireguard is active!${NC}"
    else
        echo -e "  ${RED}✖ Wireguard is not active!${NC}"
    fi

    WIREGUARD_PANEL_STATUS=$(systemctl is-active wireguard-panel.service)
    if [ "$WIREGUARD_PANEL_STATUS" == "active" ]; then
        echo -e "  ${GREEN}✔ Wireguard Panel service is active!${NC}"
    else
        echo -e "  ${RED}✖ Wireguard Panel service is inactive!${NC}"
    fi

    TELEGRAM_SERVICES_ACTIVE=0
    if [ "$(systemctl is-active telegram-bot-fa.service)" == "active" ]; then
        echo -e "  ${GREEN}✔ Telegram Bot FA service is ative!${NC}"
        TELEGRAM_SERVICES_ACTIVE=$((TELEGRAM_SERVICES_ACTIVE + 1))
    fi
    if [ "$(systemctl is-active telegram-bot-en.service)" == "active" ]; then
        echo -e "  ${GREEN}✔ Telegram Bot EN service is active!${NC}"
        TELEGRAM_SERVICES_ACTIVE=$((TELEGRAM_SERVICES_ACTIVE + 1))
    fi
    if [ "$TELEGRAM_SERVICES_ACTIVE" -eq 0 ]; then
        echo -e "  ${RED}✖ No Telegram Bot services are active!${NC}"
    fi

    echo -e "${CYAN}╚═════════════════════════════════════════════════════════════════════╝${NC}"

    if [ -f "$SCRIPT_DIR/config.yaml" ]; then
        FLASK_PORT=$(grep 'flask:' "$SCRIPT_DIR/config.yaml" -A 5 | grep 'port:' | awk '{print $2}')
        FLASK_TLS=$(grep 'flask:' "$SCRIPT_DIR/config.yaml" -A 5 | grep 'tls:' | awk '{print $2}')
        FLASK_URL=""

        MAIN_INTERFACE=$(ip -o -4 addr show | awk '{print $2}' | head -n 1)
        IPV4_ADDRESS=$(ip -o -4 addr show $MAIN_INTERFACE | awk '{print $4}' | cut -d'/' -f1)

        echo -e "${CYAN}╔═════════════════════════ ${YELLOW}Flask Information${CYAN} ═════════════════════════╗${NC}"
        if [ "$FLASK_TLS" == "true" ]; then
            SUBDOMAIN=$(grep 'cert_path:' "$SCRIPT_DIR/config.yaml" | awk -F'/' '{print $(NF-1)}')
            FLASK_URL="${SUBDOMAIN}:${FLASK_PORT}"
            echo -e "  ${LIGHT_GREEN}✔ Flask is running with TLS enabled!${NC}"
            echo -e "  ${CYAN}Homepage: ${NC}https://${YELLOW}${FLASK_URL}${NC}"
        else
            if [ ! -z "$IPV4_ADDRESS" ]; then
                echo -e "  ${YELLOW}✔ Flask is running without TLS!${NC}"
                echo -e "  ${CYAN}Homepage: ${YELLOW}${IPV4_ADDRESS}:${FLASK_PORT}${NC}"
            else
                echo -e "  ${RED}✖ No IP address found for Flask!${NC}"
            fi
        fi
        echo -e "${CYAN}╚═════════════════════════════════════════════════════════════════════╝${NC}"
    else
        echo -e "${RED}✖ Flask config not found! Please set up Flask & Gunicorn first.${NC}"
    fi

    echo -e "${CYAN}═════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN} Options:${NC}"
    echo -e "${WHITE}  0)${CYAN} View Detailed Wireguard Status${NC}" && echo
    echo -e "${WHITE}  1)${YELLOW} Setup Azumi WG dashboard${NC}"
    echo -e "${WHITE}  2)${LIGHT_GREEN} Add/Remove Wireguard Interface${NC}"
    echo -e "${WHITE}  3)${RED} Uninstall panel and core${NC}"
    echo -e "${WHITE}  4)${CYAN} Restart Wireguard-Panel / Tg-Bot / Wg-core${NC}" && echo
    echo -e "${WHITE}  5)${YELLOW} IPV4/6 Forward${NC}" && echo
    echo -e "${WHITE}  q)${RED} Exit${NC}"
    echo -e "${CYAN}═════════════════════════════════════════════════════════════════════${NC}"
}


select_stuff() {
    case $1 in
        0) wireguard_detailed_stats ;;
        1) install_requirements 
            setup_virtualenv
            create_config
            wireguardconf
            setup_permissions
            wireguard_panel;;
        2) wireguardconf ;;
        3) uninstall_mnu ;;
        4) restart_services ;;
        5) sysctl_menu ;;
        q) echo -e "${LIGHT_GREEN}Exiting...${NC}" && exit 0 ;;
        *) echo -e "${RED}Wrong choice. Please choose a valid option.${NC}" ;;
    esac
}

restart_services() {
    echo -e "${CYAN}Which service would you like to restart?${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${WHITE}  1) ${YELLOW}Wireguard Panel${NC}"
    echo -e "${WHITE}  2) ${YELLOW}Telegram Bot FA${NC}"
    echo -e "${WHITE}  3) ${YELLOW}Telegram Bot EN${NC}"
    echo -e "${WHITE}  4) ${YELLOW}Wireguard core${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    read -p "Choose an option: " choice

    case $choice in
        1) 
            echo -e "${CYAN}Restarting Wireguard Panel...${NC}"
            systemctl restart wireguard-panel.service
            ;;
        2) 
            echo -e "${CYAN}Restarting Telegram Bot FA...${NC}"
            systemctl restart telegram-bot-fa.service
            ;;
        3)
            echo -e "${CYAN}Restarting Telegram Bot EN...${NC}"
            systemctl restart telegram-bot-en.service
            ;;
        4)
            echo -e "${CYAN}Restarting wireguard core...${NC}"
            systemctl restart wireguard.service
            ;;
        *)
            echo -e "${RED}Wrong choice. Returning to main menu.${NC}"
            ;;
    esac
}


uninstall_mnu() {
    SCRIPT_DIR=$(dirname "$(realpath "$0")")

    echo -e '\033[93m══════════════════════════════════════════════════\033[0m'
    echo -e "${CYAN}Uninstallation initiated${NC}"
    echo -e '\033[93m══════════════════════════════════════════════════\033[0m'

    echo -e "${WARNING}[WARNING]:${NC} This will delete the Wireguard panel, its configs, and data ${YELLOW}[backups will be saved]."
    echo -e "${YELLOW}──────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}Do you want to continue? ${GREEN}[yes]${NC}/${RED}[no]${NC}: \c"
    read -r CONFIRM
    if [[ "$CONFIRM" != "yes" && "$CONFIRM" != "y" ]]; then
        echo -e "${CYAN}Uninstallation aborted.${NC}"
        return
    fi

    BACKUP_DIR="$SCRIPT_DIR/uninstall_backups_$(date +%Y%m%d_%H%M%S)"
    WIREGUARD_DIR="/etc/wireguard"
    SYSTEMD_SERVICE="/etc/systemd/system/wireguard-panel.service"
    BIN_DIR="/usr/local/bin"
    TELEGRAM_DIR="$SCRIPT_DIR/telegram"

    echo -e "${INFO}[INFO]${YELLOW}Backing up data to $BACKUP_DIR...${NC}"
    mkdir -p "$BACKUP_DIR"

    if [ -d "$SCRIPT_DIR/db" ]; then
        cp -r "$SCRIPT_DIR/db" "$BACKUP_DIR/db" && echo -e "${SUCCESS}[SUCCESS]Database backed up successfully.${NC}" || echo -e "${ERROR}Couldn't back up database.${NC}"
    else
        echo -e "${WARNING}No database found to back up.${NC}"
    fi

    if [ -d "$SCRIPT_DIR/backups" ]; then
        cp -r "$SCRIPT_DIR/backups" "$BACKUP_DIR/backups" && echo -e "${SUCCESS}[SUCCESS]Backups directory saved successfully.${NC}" || echo -e "${ERROR}Couldn't back up backups directory.${NC}"
    else
        echo -e "${WARNING}No backups directory found to back up.${NC}"
    fi

    if [ -d "$WIREGUARD_DIR" ]; then
        sudo cp -r "$WIREGUARD_DIR" "$BACKUP_DIR/wireguard" && echo -e "${SUCCESS}[SUCCESS]Wireguard configurations backed up successfully.${NC}" || echo -e "${ERROR}Couldn't back up Wireguard configurations.${NC}"
    else
        echo -e "${WARNING}No Wireguard configs found to back up.${NC}"
    fi

    echo -e "${INFO}[INFO]${YELLOW}Disabling and bringing down WireGuard interfaces...${NC}"
    if ls /etc/wireguard/*.conf >/dev/null 2>&1; then
        for iface in $(ls /etc/wireguard/*.conf | xargs -n1 basename | sed 's/\.conf//'); do
            sudo wg-quick down "$iface" && echo -e "${SUCCESS}[SUCCESS]Interface $iface brought down.${NC}" || echo -e "${ERROR}Couldn't bring down interface $iface.${NC}"
        done
    else
        echo -e "${WARNING}No WireGuard interfaces found to bring down.${NC}"
    fi

    if systemctl list-units --type=service | grep -q "telegram-bot-en.service"; then
        echo -e "${INFO}[INFO]${YELLOW}Stopping and disabling English Telegram bot service...${NC}"
        sudo systemctl stop telegram-bot-en.service
        sudo systemctl disable telegram-bot-en.service
        sudo rm -f /etc/systemd/system/telegram-bot-en.service && echo -e "${SUCCESS}[SUCCESS]Telegram bot (English) service removed.${NC}" || echo -e "${ERROR}Couldn't remove Telegram bot (English) service file.${NC}"
        sudo systemctl daemon-reload
    else
        echo -e "${WARNING}No English Telegram bot service found.${NC}"
    fi

    if systemctl list-units --type=service | grep -q "telegram-bot-fa.service"; then
        echo -e "${INFO}[INFO]${YELLOW}Stopping and disabling Farsi Telegram bot service...${NC}"
        sudo systemctl stop telegram-bot-fa.service
        sudo systemctl disable telegram-bot-fa.service
        sudo rm -f /etc/systemd/system/telegram-bot-fa.service && echo -e "${SUCCESS}[SUCCESS]Telegram bot (Farsi) service removed.${NC}" || echo -e "${ERROR}Couldn't remove Telegram bot (Farsi) service file.${NC}"
        sudo systemctl daemon-reload
    else
        echo -e "${WARNING}No Farsi Telegram bot service found.${NC}"
    fi

    if [ -f "$SYSTEMD_SERVICE" ]; then
        echo -e "${INFO}[INFO]${YELLOW}Stopping & disabling Wireguard Panel service...${NC}"
        sudo systemctl stop wireguard-panel.service
        sudo systemctl disable wireguard-panel.service
        sudo rm -f "$SYSTEMD_SERVICE" && echo -e "${SUCCESS}[SUCCESS]Service file removed successfully.${NC}" || echo -e "${ERROR}Couldn't remove service file.${NC}"
        sudo systemctl daemon-reload
    else
        echo -e "${WARNING}Wireguard panel service is not installed.${NC}"
    fi

    echo -e "${INFO}[INFO]${YELLOW}Deleting Wireguard panel files and configs...${NC}"
    rm -rf "$SCRIPT_DIR/db" "$SCRIPT_DIR/backups" "$SCRIPT_DIR/venv" "$SCRIPT_DIR/config.yaml" \
        "$SCRIPT_DIR/install_telegram.sh" "$SCRIPT_DIR/install_telegram-fa.sh" || echo -e "${ERROR}Couldn't remove some files.${NC}"
    sudo rm -rf "$BIN_DIR/wireguard-panel" || echo -e "${ERROR}Couldn't remove Wireguard panel files from /usr/local/bin.${NC}"

    if [ -d "$WIREGUARD_DIR" ]; then
        sudo rm -rf "$WIREGUARD_DIR" && echo -e "${SUCCESS}[SUCCESS]Wireguard configs removed successfully.${NC}" || echo -e "${ERROR}Couldn't remove Wireguard configurations.${NC}"
    fi

    echo -e "${INFO}[INFO]${YELLOW}Freeing up space...${NC}"
    sudo apt autoremove -y && sudo apt autoclean -y && echo -e "${SUCCESS}[SUCCESS]Space cleared successfully.${NC}" || echo -e "${ERROR}Couldn't free up space.${NC}"

    echo -e "\n${YELLOW}┌──────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│                                                                      │${NC}"
    echo -e "${YELLOW}│                  ${CYAN}Uninstallation Complete!${NC}                         ${YELLOW}   │${NC}"
    echo -e "${YELLOW}│                                                                      │${NC}"
    echo -e "${YELLOW}├──────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${YELLOW}│ ${GREEN}The Wireguard Panel and associated services have been ${NC}"
    echo -e "${YELLOW}│ ${GREEN}successfully removed.${NC}"
    echo -e "${YELLOW}│                                                           ${NC}"
    echo -e "${YELLOW}│ ${RED}NOTE:${NC} The script itself has not been removed.             ${NC}"
    echo -e "${YELLOW}│ You can manually delete it later using:                   ${NC}"
    echo -e "${YELLOW}│ ${GREEN}rm -f $SCRIPT_DIR/$(basename "$0")${NC}"
    echo -e "${YELLOW}│                                                           ${NC}"
    echo -e "${YELLOW}│ ${CYAN}All backups have been saved in:                        ${NC}"
    echo -e "${YELLOW}│ ${GREEN}$BACKUP_DIR${NC}"
    echo -e "${YELLOW}│                                                           ${NC}"
    echo -e "${YELLOW}└──────────────────────────────────────────────────────────────────────┘${NC}"
    echo -e "${CYAN}Press Enter to exit...${NC}" && read
}



install_requirements() {
    echo -e "\033[92m ^ ^\033[0m"
    echo -e "\033[92m(\033[91mO,O\033[92m)\033[0m"
    echo -e "\033[92m(   ) \033[92mRequirements\033[0m"
    echo -e '\033[92m "-"\033[93m══════════════════════════════════\033[0m'

    echo -e "${INFO}[INFO]${YELLOW}Installing required Stuff...${NC}"
    echo -e '\033[93m══════════════════════════════════\033[0m'

    sudo apt update && sudo apt install -y python3 python3-pip python3-venv git redis nftables iptables wireguard-tools iproute2 \
        fonts-dejavu certbot curl software-properties-common wget || {
        echo -e "${ERROR}Installation failed. Ensure you are using root privileges.${NC}"
        exit 1
    }

    echo -e "${INFO}[INFO]${YELLOW}Starting Redis server...${NC}"
    sudo systemctl enable redis-server.service
    sudo systemctl start redis-server.service || {
        echo -e "${ERROR}Couldn't start Redis server. Please check system logs.${NC}"
        exit 1
    }

    echo -e "${SUCCESS}[SUCCESS]All required stuff have been installed successfully.${NC}"
    echo -e "${CYAN}Press Enter to continue...${NC}" && read
}


setup_virtualenv() {
    echo -e "\033[92m ^ ^\033[0m"
    echo -e "\033[92m(\033[91mO,O\033[92m)\033[0m"
    echo -e "\033[92m(   ) \033[92mVirtual env Setup\033[0m"
    echo -e '\033[92m "-"\033[93m══════════════════════════════════\033[0m'
    echo -e "${INFO}[INFO]${YELLOW}Setting up Virtual Env...${NC}"

    PYTHON_BIN=$(which python3)
    if [ -z "$PYTHON_BIN" ]; then
        echo -e "${ERROR}Python3 is not installed or not in PATH. install Python3.${NC}"
        exit 1
    fi

    echo -e "${INFO}[INFO]${YELLOW}Using Python binary: $PYTHON_BIN${NC}"

    echo -e "${INFO}[INFO]${YELLOW}Creating virtual env...${NC}"
    "$PYTHON_BIN" -m venv "$SCRIPT_DIR/venv" || {
        echo -e "${ERROR}Couldn't create virtual env. Plz check Python installation and permissions.${NC}"
        exit 1
    }

    echo -e "${INFO}[INFO]${YELLOW}Activating virtual env...${NC}"
    source "$SCRIPT_DIR/venv/bin/activate" || {
        echo -e "${ERROR}Couldn't activate virtual environment. Please check if the virtualenv module is installed.${NC}"
        exit 1
    }

    echo -e "${INFO}[INFO]${YELLOW}Upgrading pip and installing stuff...${NC}"
    pip install --upgrade pip || {
        echo -e "${ERROR}Couldn't upgrade pip. Change DNS.${NC}"
        deactivate
        exit 1
    }

    pip install \
        python-dotenv \
        python-telegram-bot \
        aiohttp \
        matplotlib \
        qrcode \
        "python-telegram-bot[job-queue]" \
        pyyaml \
        flask-session \
        Flask \
        SQLAlchemy \
        Flask-Limiter \
        Flask-Bcrypt \
        Flask-Caching \
        jsonschema \
        psutil \
        requests \
        pynacl \
        apscheduler \
        redis \
        werkzeug \
        jinja2 \
        fasteners \
        gunicorn \
        pexpect \
        cryptography \
        Pillow \
        arabic-reshaper \
        python-bidi || {
            echo -e "${ERROR}Couldn't install Python requirements. check the error messages and try again.${NC}"
            deactivate
            exit 1
        }

    echo -e "${INFO}[INFO]${YELLOW}Installing stuff...${NC}"
    sudo apt-get update || {
        echo -e "${ERROR}Couldn't update package list. Please check your DNS or network connection.${NC}"
        deactivate
        exit 1
    }

    sudo apt-get install -y libsystemd-dev || {
        echo -e "${ERROR}Couldn't install libsystemd-dev. Check your package manager or system settings.${NC}"
        deactivate
        exit 1
    }

    echo -e "${SUCCESS}[SUCCESS]Virtual env set up successfully.${NC}"
    deactivate
    echo -e "${CYAN}Press Enter to exit...${NC}" && read
}



setup_permissions() {
    echo -e "\033[92m ^ ^\033[0m"
    echo -e "\033[92m(\033[91mO,O\033[92m)\033[0m"
    echo -e "\033[92m(   ) \033[92mRead & Write permissions\033[0m"
    echo -e '\033[92m "-"\033[93m══════════════════════════════════\033[0m'
    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for files & directories...${NC}"
    echo -e '\033[93m══════════════════════════════════\033[0m'

    CONFIG_FILE="$SCRIPT_DIR/config.yaml"
    DB_DIR="$SCRIPT_DIR/db"
    BACKUPS_DIR="$SCRIPT_DIR/backups"
    TELEGRAM_DIR="$SCRIPT_DIR/telegram"
    TELEGRAM_YAML="$TELEGRAM_DIR/telegram.yaml"
    TELEGRAM_JSON="$TELEGRAM_DIR/config.json"
    INSTALL_PROGRESS_JSON="$SCRIPT_DIR/install_progress.json"
    API_JSON="$SCRIPT_DIR/api.json"
    STATIC_FONTS_DIR="$SCRIPT_DIR/static/fonts"

    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for $CONFIG_FILE...${NC}"
    chmod 644 "$CONFIG_FILE" 2>/dev/null || echo -e "${WARNING}Warning: Couldn't set permissions for $CONFIG_FILE.${NC}"

    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for $DB_DIR...${NC}"
    chmod -R 600 "$DB_DIR" 2>/dev/null || echo -e "${WARNING}Warning: Couldn't set permissions for $DB_DIR.${NC}"

    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for $BACKUPS_DIR...${NC}"
    chmod -R 700 "$BACKUPS_DIR" 2>/dev/null || echo -e "${WARNING}Warning: Couldn't set permissions for $BACKUPS_DIR.${NC}"

    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for $TELEGRAM_YAML...${NC}"
    chmod 644 "$TELEGRAM_YAML" 2>/dev/null || echo -e "${WARNING}Warning: $TELEGRAM_YAML not found.${NC}"

    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for $TELEGRAM_JSON...${NC}"
    chmod 644 "$TELEGRAM_JSON" 2>/dev/null || echo -e "${WARNING}Warning: $TELEGRAM_JSON not found.${NC}"

    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for $INSTALL_PROGRESS_JSON...${NC}"
    chmod 644 "$INSTALL_PROGRESS_JSON" 2>/dev/null || echo -e "${WARNING}Warning: $INSTALL_PROGRESS_JSON not found.${NC}"

    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for $API_JSON...${NC}"
    chmod 644 "$API_JSON" 2>/dev/null || echo -e "${WARNING}Warning: $API_JSON not found.${NC}"

    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for $SCRIPT_DIR/setup.sh...${NC}"
    chmod 744 "$SCRIPT_DIR/setup.sh" 2>/dev/null || echo -e "${WARNING}Warning: setup.sh not found.${NC}"

    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for $SCRIPT_DIR/install_telegram.sh...${NC}"
    chmod 744 "$SCRIPT_DIR/install_telegram.sh" 2>/dev/null || echo -e "${WARNING}Warning: install_telegram.sh not found.${NC}"

    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for $SCRIPT_DIR/install_telegram-fa.sh...${NC}"
    chmod 744 "$SCRIPT_DIR/install_telegram-fa.sh" 2>/dev/null || echo -e "${WARNING}Warning: install_telegram-fa.sh not found.${NC}"

    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for $STATIC_FONTS_DIR...${NC}"
    chmod -R 644 "$STATIC_FONTS_DIR" 2>/dev/null || echo -e "${WARNING}Warning: $STATIC_FONTS_DIR not found.${NC}"

    if [ -d "/etc/wireguard" ]; then
        echo -e "${INFO}[INFO]${YELLOW}Setting permissions for /etc/wireguard...${NC}"
        sudo chmod -R 755 /etc/wireguard || echo -e "${ERROR}Couldn't set permissions for /etc/wireguard. use sudo -i.${NC}"
    else
        echo -e "${WARNING}/etc/wireguard directory does not exist.${NC}"
    fi

    echo -e "${INFO}[INFO]${YELLOW}Checking permissions for other directories...${NC}"

    find "$SCRIPT_DIR" -type f ! -path "$SCRIPT_DIR/venv/*" -exec chmod 644 {} \; || echo -e "${WARNING}Could not update file permissions in $SCRIPT_DIR.${NC}"
    find "$SCRIPT_DIR" -type d -exec chmod 755 {} \; || echo -e "${WARNING}Could not update directory permissions in $SCRIPT_DIR.${NC}"

    echo -e "${SUCCESS}[SUCCESS]Permissions have been set successfully.${NC}"
    echo -e "${CYAN}Press Enter to continue...${NC}" && read
}



setup_tls() {
    echo -e '\033[93m══════════════════════════════════\033[0m'
    echo -e "${YELLOW}Do you want to ${GREEN}enable TLS${YELLOW}? ${GREEN}[yes]${NC}/${RED}[no]${NC}: ${NC} \c"

    while true; do
        read -e ENABLE_TLS
        ENABLE_TLS=$(echo "$ENABLE_TLS" | tr '[:upper:]' '[:lower:]')  
        
        if [[ "$ENABLE_TLS" == "yes" || "$ENABLE_TLS" == "no" ]]; then
            echo -e "${INFO}[INFO] TLS enabled: ${GREEN}$ENABLE_TLS${NC}" 
            break
        else
            echo -e "${RED}Wrong input. Please type ${GREEN}yes${RED} or ${RED}no${NC}: \c"
        fi
    done

    if [ "$ENABLE_TLS" = "yes" ]; then
        while true; do
            echo -e "${YELLOW}Enter your ${GREEN}Sub-domain name${YELLOW}:${NC} \c"
            read -e DOMAIN_NAME
            if [ -n "$DOMAIN_NAME" ]; then
                echo -e "${INFO}[INFO] Sub-domain set to: ${GREEN}$DOMAIN_NAME${NC}" 
                break
            else
                echo -e "${RED}Sub-domain name cannot be empty. Please try again.${NC}"
            fi
        done

        while true; do
            echo -e "${YELLOW}Enter your ${GREEN}Email address${YELLOW}:${NC} \c"
            read -e EMAIL
            if [[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                echo -e "${INFO}[INFO] Email set to: ${GREEN}$EMAIL${NC}" 
                break
            else
                echo -e "${RED}Wrong email address. Please enter a valid email.${NC}"
            fi
        done

        echo -e "${INFO}[INFO]${YELLOW} Requesting a TLS certificate from Let's Encrypt...${NC}"

        if sudo certbot certonly --standalone --agree-tos --email "$EMAIL" -d "$DOMAIN_NAME"; then
            CERT_PATH="/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem"
            KEY_PATH="/etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem"

            echo -e "${SUCCESS}[SUCCESS] TLS certificate successfully obtained for ${GREEN}$DOMAIN_NAME${NC}."

            CONFIG_FILE="$SCRIPT_DIR/config.yaml"

            if [ ! -f "$CONFIG_FILE" ]; then
                echo -e "${INFO}[INFO]${YELLOW} config.yaml does not exist. Creating it...${NC}"
                cat <<EOF > "$CONFIG_FILE"
tls: false
cert_path: ""
key_path: ""
EOF
            fi

            echo -e "${INFO}[INFO]${YELLOW} Updating config.yaml with TLS settings...${NC}"
            sed -i "s|tls: false|tls: true|g" "$CONFIG_FILE"
            sed -i "s|cert_path: \"\"|cert_path: \"$CERT_PATH\"|g" "$CONFIG_FILE"
            sed -i "s|key_path: \"\"|key_path: \"$KEY_PATH\"|g" "$CONFIG_FILE"

            echo -e "${SUCCESS}[SUCCESS] TLS configuration successfully added to config.yaml.${NC}"
        else
            echo -e "${RED}[ERROR] Failed to obtain TLS certificate. Please check your sub-domain and email address.${NC}"
        fi
    else
        echo -e "${CYAN}[INFO] Skipping TLS setup.${NC}"
    fi
}


show_flask_info() {
    echo -e "\033[92m ^ ^\033[0m"
    echo -e "\033[92m(\033[91mO,O\033[92m)\033[0m"
    echo -e "\033[92m(   ) \033[92mFlask Access Info\033[0m"
    echo -e '\033[92m "-"\033[93m══════════════════════════════════\033[0m'

    FLASK_PORT=$(grep -i 'port' "$SCRIPT_DIR/config.yaml" | awk '{print $2}')
    TLS_ENABLED=$(grep -i 'tls' "$SCRIPT_DIR/config.yaml" | awk '{print $2}')
    CERT_PATH=$(grep -i 'cert_path' "$SCRIPT_DIR/config.yaml" | awk '{print $2}')
    FLASK_PUBLIC_IP=$(curl -s http://checkip.amazonaws.com) 

    if [ "$TLS_ENABLED" == "true" ]; then
        SUBDOMAIN=$(echo "$CERT_PATH" | awk -F'/' '{print $(NF-1)}')  

       echo -e "\033[93m══════════════════════════════════\033[0m"
       echo -e "${LIGHT_GREEN}🎉 TLS is enabled! 🎉${NC}"
       echo -e "${CYAN}You can access your Flask app at:${NC}"
       echo -e "${LIGHT_BLUE}https://${SUBDOMAIN}:${FLASK_PORT}${NC}"
       echo -e "${CYAN}Ensure your DNS is correctly pointed to this subdomain.${NC}"
       echo -e "\033[93m══════════════════════════════════\033[0m"

    else
        echo -e "\033[93m══════════════════════════════════\033[0m"
        echo -e "${LIGHT_GREEN}🔥 Flask is running without TLS! 🔥${NC}"
        echo -e "${CYAN}You can access your Flask app at:${NC}"
        echo -e "${LIGHT_BLUE}${FLASK_PUBLIC_IP}:${FLASK_PORT}${NC}"
        echo -e "${CYAN}You can use this IP to access the app directly.${NC}"
        echo -e "\033[93m══════════════════════════════════\033[0m"
    fi

}

wireguardconf() {
    echo -e "\n${BLUE}[INFO]=== Wireguard Installation and Configuration ===${NC}\n"

    if ! command -v wg &>/dev/null; then
        echo -e "${BLUE}[INFO] Wireguard not found. Installing...${NC}"
        apt-get update -y && apt-get install -y wireguard
        if [ $? -ne 0 ]; then
            echo -e "${RED}[ERROR] Couldn't install Wireguard.${NC}"
            return 1
        fi
        echo -e "${SUCCESS}[SUCCESS] Wireguard installed successfully!${NC}"
    else
        echo -e "${INFO}[INFO] Wireguard is already installed. Skipping...${NC}"
    fi

    echo -e '\033[93m══════════════════════════════════════════════════\033[0m'

    while true; do
        echo -e "${YELLOW}Enter the ${BLUE}Wireguard ${GREEN}interface name${NC} (example wg0):${NC} \c"
        read -e WG_NAME
        if [ -n "$WG_NAME" ]; then
            echo -e "${INFO}[INFO] Interface Name set to: ${GREEN}$WG_NAME${NC}"
            break
        else
            echo -e "${RED}Interface name cannot be empty. Please try again.${NC}"
        fi
    done

    local WG_CONFIG="/etc/wireguard/${WG_NAME}.conf"
    local PRIVATE_KEY
    PRIVATE_KEY=$(wg genkey)

    local SERVER_INTERFACE
    SERVER_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
    [ -z "${SERVER_INTERFACE}" ] && SERVER_INTERFACE="eth0"

    while true; do
        echo -e "${YELLOW}Enter the ${BLUE}Wireguard ${GREEN}private IP address${NC} (example 176.66.66.1/24):${NC} \c"
        read -e WG_ADDRESS
        if [[ "$WG_ADDRESS" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
            echo -e "${INFO}[INFO] Private IP Address set to: ${GREEN}$WG_ADDRESS${NC}"
            break
        else
            echo -e "${RED}Wrong IP address format. Please try again.${NC}"
        fi
    done

    while true; do
        echo -e "${YELLOW}Enter the ${BLUE}Wireguard ${GREEN}listen port${NC} (example 20820):${NC} \c"
        read -e WG_PORT
        if [[ "$WG_PORT" =~ ^[0-9]+$ ]] && [ "$WG_PORT" -ge 1 ] && [ "$WG_PORT" -le 65535 ]; then
            echo -e "${INFO}[INFO] Listen Port set to: ${GREEN}$WG_PORT${NC}"
            break
        else
            echo -e "${RED}Wrong port number. Please enter a valid port between 1 and 65535.${NC}"
        fi
    done

    while true; do
        echo -e "${YELLOW}Enter the ${BLUE}MTU ${GREEN}size${NC} (example 1420):${NC} \c"
        read -e MTU
        if [[ "$MTU" =~ ^[0-9]+$ ]]; then
            echo -e "${INFO}[INFO] MTU Size set to: ${GREEN}$MTU${NC}"
            break
        else
            echo -e "${RED}Wrong MTU size. Please try again.${NC}"
        fi
    done

    while true; do
        echo -e "${YELLOW}Enter the ${BLUE}DNS ${GREEN}servers ${NC}(example 1.1.1.1):${NC} \c"
        read -e DNS
        if [ -n "$DNS" ]; then
            echo -e "${INFO}[INFO] DNS Servers set to: ${GREEN}$DNS${NC}"
            break
        else
            echo -e "${RED}DNS servers cannot be empty. Please try again.${NC}"
        fi
    done

    echo -e '\033[93m══════════════════════════════════════════════════\033[0m'

    if [ ! -d "/etc/wireguard" ]; then
        echo -e "${INFO}[INFO] Creating /etc/wireguard directory...${NC}"
        sudo mkdir -p /etc/wireguard
    fi

    echo -e "${INFO}[INFO] Generating Wireguard config at ${WG_CONFIG}...${NC}"
    cat <<EOL > "${WG_CONFIG}"
[Interface]
Address = ${WG_ADDRESS}
ListenPort = ${WG_PORT}
PrivateKey = ${PRIVATE_KEY}
MTU = ${MTU}
DNS = ${DNS}

PostUp = iptables -I INPUT -p udp --dport ${WG_PORT} -j ACCEPT
PostUp = iptables -I FORWARD -i ${SERVER_INTERFACE} -o ${WG_NAME} -j ACCEPT
PostUp = iptables -I FORWARD -i ${WG_NAME} -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o ${SERVER_INTERFACE} -j MASQUERADE

PostDown = iptables -D INPUT -p udp --dport ${WG_PORT} -j ACCEPT
PostDown = iptables -D FORWARD -i ${SERVER_INTERFACE} -o ${WG_NAME} -j ACCEPT
PostDown = iptables -D FORWARD -i ${WG_NAME} -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o ${SERVER_INTERFACE} -j MASQUERADE
EOL

    chmod 600 "${WG_CONFIG}" || { echo -e "${RED}[ERROR] Couldn't set permissions on ${WG_CONFIG}.${NC}"; return 1; }

    echo -e "${INFO}[INFO] Bringing up Wireguard interface ${WG_NAME}...${NC}"
    if ! wg-quick up "${WG_NAME}"; then
        echo -e "${RED}[ERROR] Couldn't bring up ${WG_NAME}. Check config or logs.${NC}"
        return 1
    fi

    echo -e "${INFO}[INFO] Enabling Wireguard interface ${WG_NAME}${NC}"
    if ! systemctl enable "wg-quick@${WG_NAME}"; then
        echo -e "${RED}[ERROR] Couldn't enable wg-quick@${WG_NAME} on boot.${NC}"
        return 1
    fi

    echo -e "\n${GREEN}Wireguard interface ${WG_NAME} created & activated successfully!${NC}"

    echo -e "${CYAN}Press Enter to continue...${NC}"
    read -r
}



create_config() {
    echo -e "\033[92m ^ ^\033[0m"
    echo -e "\033[92m(\033[91mO,O\033[92m)\033[0m"
    echo -e "\033[92m(   ) \033[92mFlask Setup\033[0m"
    echo -e '\033[92m "-"\033[93m══════════════════════════════════\033[0m'
    
    echo -e "${INFO}[INFO] Creating or updating Flask setup...${NC}"
    echo -e '\033[93m══════════════════════════════════\033[0m'

    while true; do
        echo -ne "${YELLOW}Enter the ${GREEN}Flask port ${YELLOW}[example: 8000, default: 5000]: ${NC}"
        read -e FLASK_PORT
        FLASK_PORT=${FLASK_PORT:-5000}
        if [[ "$FLASK_PORT" =~ ^[0-9]+$ ]] && [ "$FLASK_PORT" -ge 1 ] && [ "$FLASK_PORT" -le 65535 ]; then
            echo -e "${CYAN}[INFO] Flask Port: ${GREEN}$FLASK_PORT${NC}"
            break
        else
            echo -e "${RED}[ERROR] Invalid port. Please enter a valid number between 1 and 65535.${NC}"
        fi
    done

    echo -ne "${YELLOW}Enable ${GREEN}Flask ${YELLOW}debug mode? ${GREEN}[yes]${NC}/${RED}[no]${NC} [default: no]: ${NC}"
    read -e FLASK_DEBUG
    FLASK_DEBUG=${FLASK_DEBUG:-no}
    FLASK_DEBUG=$(echo "$FLASK_DEBUG" | grep -iq "^y" && echo "true" || echo "false")
    echo -e "\n${CYAN}[INFO] Flask Debug Mode: ${GREEN}$FLASK_DEBUG${NC}"

    while true; do
        echo -ne "${YELLOW}Enter the number of ${GREEN}Gunicorn workers ${YELLOW}[default: 2]: ${NC}"
        read -e GUNICORN_WORKERS
        GUNICORN_WORKERS=${GUNICORN_WORKERS:-2}
        if [[ "$GUNICORN_WORKERS" =~ ^[0-9]+$ ]]; then
            echo -e "\n${CYAN}[INFO] Gunicorn Workers: ${GREEN}$GUNICORN_WORKERS${NC}"
            break
        else
            echo -e "\n${RED}[ERROR] Invalid number. Please enter a valid number.${NC}"
        fi
    done

    while true; do
        echo -ne "${YELLOW}Enter the number of ${GREEN}Gunicorn threads ${YELLOW}[default: 1]: ${NC}"
        read -e GUNICORN_THREADS
        GUNICORN_THREADS=${GUNICORN_THREADS:-1}
        if [[ "$GUNICORN_THREADS" =~ ^[0-9]+$ ]]; then
            echo -e "\n${CYAN}[INFO] Gunicorn Threads: ${GREEN}$GUNICORN_THREADS${NC}"
            break
        else
            echo -e "\n${RED}[ERROR] Invalid number. Please enter a valid number.${NC}"
        fi
    done

    while true; do
        echo -ne "${YELLOW}Enter the ${GREEN}Gunicorn timeout ${YELLOW}in seconds [default: 120]: ${NC}"
        read -e GUNICORN_TIMEOUT
        GUNICORN_TIMEOUT=${GUNICORN_TIMEOUT:-120}
        if [[ "$GUNICORN_TIMEOUT" =~ ^[0-9]+$ ]]; then
            echo -e "\n${CYAN}[INFO] Gunicorn Timeout: ${GREEN}$GUNICORN_TIMEOUT${NC}"
            break
        else
            echo -e "\n${RED}[ERROR] Invalid timeout. Please enter a valid number.${NC}"
        fi
    done

    while true; do
        echo -ne "${YELLOW}Enter the ${GREEN}Gunicorn log level ${YELLOW}[default: info]: ${NC}"
        read -e GUNICORN_LOGLEVEL
        GUNICORN_LOGLEVEL=${GUNICORN_LOGLEVEL:-info}
        if [[ "$GUNICORN_LOGLEVEL" =~ ^(debug|info|warning|error|critical)$ ]]; then
            echo -e "\n${CYAN}[INFO] Gunicorn Log Level: ${GREEN}$GUNICORN_LOGLEVEL${NC}"
            break
        else
            echo -e "\n${RED}[ERROR] Invalid log level. Valid options: debug, info, warning, error, critical.${NC}"
        fi
    done

    while true; do
        echo -ne "${YELLOW}Enter the ${GREEN}Flask ${YELLOW}secret key ${NC}(used for session management): ${NC}"
        read -e FLASK_SECRET_KEY
        if [ -n "$FLASK_SECRET_KEY" ]; then
            echo -e "\n${CYAN}[INFO] Flask Secret Key: ${GREEN}$FLASK_SECRET_KEY${NC}"
            break
        else
            echo -e "\n${RED}[ERROR] Secret key cannot be empty. Please enter a valid value.${NC}"
        fi
    done

    setup_tls

    echo -e '\033[93m══════════════════════════════════\033[0m'
    echo -e "${INFO}[INFO] Creating config.yaml file...${NC}"

    cat <<EOL >"$SCRIPT_DIR/config.yaml"
flask:
  port: $FLASK_PORT
  tls: $([ "$ENABLE_TLS" = "yes" ] && echo "true" || echo "false")
  cert_path: "$CERT_PATH"
  key_path: "$KEY_PATH"
  secret_key: "$FLASK_SECRET_KEY"
  debug: $FLASK_DEBUG

gunicorn:
  workers: $GUNICORN_WORKERS
  threads: $GUNICORN_THREADS
  loglevel: "$GUNICORN_LOGLEVEL"
  timeout: $GUNICORN_TIMEOUT
  accesslog: "$GUNICORN_ACCESS_LOG"
  errorlog: "$GUNICORN_ERROR_LOG"

wireguard:
  config_dir: "/etc/wireguard"
EOL

    if [[ $? -eq 0 ]]; then
        echo -e "${LIGHT_GREEN}config.yaml created successfully.${NC}"
    else
        echo -e "${RED}[ERROR] Couldn't create config.yaml. Please check for errors.${NC}"
    fi

    echo -e "${CYAN}Press Enter to continue...${NC}" && read
}



wireguard_panel() {
    echo -e "\033[92m ^ ^\033[0m"
    echo -e "\033[92m(\033[91mO,O\033[92m)\033[0m"
    echo -e "\033[92m(   ) \033[92mWireguard Service env\033[0m"
    echo -e '\033[92m "-"\033[93m══════════════════════════════════\033[0m'
    echo -e "${INFO}[INFO]Wireguard Service${NC}"
    echo -e '\033[93m══════════════════════════════════\033[0m'

    APP_FILE="$SCRIPT_DIR/app.py"
    VENV_DIR="$SCRIPT_DIR/venv"
    SERVICE_FILE="/etc/systemd/system/wireguard-panel.service"

    if [ ! -f "$APP_FILE" ]; then
        echo -e "${RED}[Error] $APP_FILE not found. make sure that Wireguard panel is in the correct directory.${NC}"
        echo -e "${CYAN}Press Enter to continue...${NC}" && read
        return 1
    fi

    if [ ! -d "$VENV_DIR" ]; then
        echo -e "${RED}[Error] Virtual env not found in $VENV_DIR. install it first from the script menu.${NC}"
        echo -e "${CYAN}Press Enter to continue...${NC}" && read
        return 1
    fi

    sudo bash -c "cat > $SERVICE_FILE" <<EOL
[Unit]
Description=Wireguard Panel
After=network.target

[Service]
User=$(whoami)
WorkingDirectory=$SCRIPT_DIR
ExecStart=$VENV_DIR/bin/python3 $APP_FILE
Restart=always
Environment=PATH=$VENV_DIR/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=LANG=en_US.UTF-8
Environment=LC_ALL=en_US.UTF-8

[Install]
WantedBy=multi-user.target
EOL

    sudo chmod 644 "$SERVICE_FILE"
    sudo systemctl daemon-reload
    sudo systemctl enable wireguard-panel.service
    sudo systemctl restart wireguard-panel.service

    if [ "$(sudo systemctl is-active wireguard-panel.service)" = "active" ]; then
        echo -e "${LIGHT_GREEN}[Success] Wireguard Panel service is running successfully.${NC}"
    else
        echo -e "${RED}[Error] Couldn't start the Wireguard Panel service.${NC}"
        echo -e "${CYAN}Press Enter to continue...${NC}" && read
        return 1
    fi

    show_flask_info

    echo -e "${CYAN}Press Enter to continue...${NC}" && read
}


SYSCTL_CONF="/etc/sysctl.conf"
BACKUP_CONF="/etc/sysctl.conf.backup"

declare -A SETTINGS=(
    ["net.ipv4.ip_forward"]="1"
    ["net.ipv6.conf.all.disable_ipv6"]="0"
    ["net.ipv6.conf.default.disable_ipv6"]="0"
    ["net.ipv6.conf.all.forwarding"]="1"
)

backup_sysctl() {
    if [ ! -f "$BACKUP_CONF" ]; then
        sudo cp "$SYSCTL_CONF" "$BACKUP_CONF"
        echo -e "\033[93mBackup created at $BACKUP_CONF\033[0m"
    else
        echo -e "\033[92mBackup already exists at $BACKUP_CONF\033[0m"
    fi
}

apply() {
    local current_settings
    declare -A current_settings

    while IFS='=' read -r key value; do
        if [[ "$key" =~ ^# ]] || [[ -z "$key" ]]; then
            continue
        fi
        current_settings["$key"]=$(echo "$value" | xargs)  
    done < "$SYSCTL_CONF"

    for key in "${!SETTINGS[@]}"; do
        value="${SETTINGS[$key]}"
        if [[ "${current_settings[$key]}" != "$value" ]]; then
            echo "$key = $value" | sudo tee -a "$SYSCTL_CONF" > /dev/null
            sudo sysctl -w "$key=$value"
            echo -e "\033[92mApplied \033[94m$key \033[93m= \033[94m$value\033[0m"
        else
            echo -e "\033[94m$key\033[93m is already set to $value\033[0m"
        fi
    done
}

restore_backup() {
    if [ -f "$BACKUP_CONF" ]; then
        sudo cp "$BACKUP_CONF" "$SYSCTL_CONF"
        sudo sysctl -p
        echo -e "\033[93mRestored configuration from $BACKUP_CONF\033[0m"
    else
        echo -e "\033[91mNo backup found at $BACKUP_CONF\033[0m"
    fi
}

sysctl_menu() {
    echo -e "\033[92m ^ ^\033[0m"
    echo -e "\033[92m(\033[91mO,O\033[92m)\033[0m"
    echo -e "\033[92m(   ) \033[92mWireguard Service env\033[0m"
    echo -e '\033[92m "-"\033[93m══════════════════════════════════\033[0m'
    echo -e "\033[93mChoose an option:\033[0m"
    echo -e "\033[92m1.\033[0m Backup sysctl configuration"
    echo -e "\033[92m2.\033[0m Apply sysctl settings"
    echo -e "\033[92m3.\033[0m Restore sysctl configuration from backup"
    echo -e '\033[93m══════════════════════════════════\033[0m'
    read -rp "Choose [1-3]: " CHOICE

    case "$CHOICE" in
        1)
            backup_sysctl
            ;;
        2)
            apply
            ;;
        3)
            restore_backup
            ;;
        *)
            echo -e "\033[91mWrong choice. Exiting.\033[0m"
            ;;
    esac
}


while true; do
    display_menu
    echo -e "${NC}choose an option [1-9]:${NC} \c"
    read -r USER_CHOICE
    select_stuff "$USER_CHOICE"
done
