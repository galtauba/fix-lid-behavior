#!/bin/bash

# === Colors ===
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# === Script location and log file ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/fix-lid-behavior-$(date '+%Y-%m-%d_%H-%M-%S').log"
CONFIG_FILE="/etc/systemd/logind.conf"
NEEDED_KEYS=("HandleLidSwitch" "HandleLidSwitchDocked" "HandleLidSwitchExternalPower")
NEEDED_VALUE="ignore"
CHANGED=false

# === Logging helper ===
log_and_echo() {
    echo -e "$1"
    echo -e "$(echo "$1" | sed 's/\x1b\[[0-9;]*m//g')" >> "$LOG_FILE"
}

echo "===== $(date) =====" >> "$LOG_FILE"

# === Pre-check 1: systemd check ===
if ! pidof systemd >/dev/null; then
    log_and_echo "${RED}ERROR:${NC} This system does not appear to be running systemd."
    exit 1
fi

# === Pre-check 2: sudo privileges ===
if ! sudo -n true 2>/dev/null; then
    log_and_echo "${RED}ERROR:${NC} This script requires sudo privileges."
    exit 1
fi

# === Pre-check 3: config file exists ===
if [ ! -f "$CONFIG_FILE" ]; then
    log_and_echo "${RED}ERROR:${NC} Config file not found at $CONFIG_FILE"
    exit 1
fi

# === Pre-check 4: log directory writable ===
if [ ! -w "$SCRIPT_DIR" ]; then
    log_and_echo "${RED}ERROR:${NC} Cannot write to $SCRIPT_DIR"
    exit 1
fi

log_and_echo "${BLUE}[1/5] Checking if backup exists...${NC}"
if [ ! -f "${CONFIG_FILE}.backup" ]; then
    sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"
    log_and_echo "      ${GREEN}Backup created at ${CONFIG_FILE}.backup${NC}"
else
    log_and_echo "      ${GREEN}Backup already exists.${NC}"
fi

# === Update config entries if needed ===
update_key() {
    local key="$1"
    if grep -q "^$key=" "$CONFIG_FILE"; then
        sudo sed -i "s|^$key=.*|$key=$NEEDED_VALUE|" "$CONFIG_FILE"
        CHANGED=true
        log_and_echo "      ${YELLOW}Updated $key${NC}"
    elif grep -q "^#$key=" "$CONFIG_FILE"; then
        sudo sed -i "s|^#$key=.*|$key=$NEEDED_VALUE|" "$CONFIG_FILE"
        CHANGED=true
        log_and_echo "      ${YELLOW}Un-commented and updated $key${NC}"
    else
        echo "$key=$NEEDED_VALUE" | sudo tee -a "$CONFIG_FILE" > /dev/null
        CHANGED=true
        log_and_echo "      ${YELLOW}Appended $key${NC}"
    fi
}

log_and_echo "${BLUE}[2/5] Validating lid switch settings...${NC}"
for key in "${NEEDED_KEYS[@]}"; do
    current=$(grep -E "^\s*#?$key=" "$CONFIG_FILE" | tail -n 1)
    if [[ "$current" != "$key=$NEEDED_VALUE" ]]; then
        log_and_echo "      ${YELLOW}$key needs to be fixed.${NC}"
        update_key "$key"
    else
        log_and_echo "      ${GREEN}$key is already set correctly.${NC}"
    fi
done

log_and_echo "${BLUE}[3/5] Verifying if restart is needed...${NC}"
if [ "$CHANGED" = true ]; then
    log_and_echo "${BLUE}[4/5] Restarting systemd-logind service...${NC}"
    sudo systemctl restart systemd-logind
    log_and_echo "      ${GREEN}Service restarted.${NC}"
else
    log_and_echo "${BLUE}[4/5]${NC} ${GREEN}No restart needed. Configuration is up-to-date.${NC}"
fi

log_and_echo "${BLUE}[5/5] Done!${NC}"
