#!/bin/bash

# Script to create a Samba share with no password and full read/write access
# Usage: ./setup_samba_share.sh /path/to/directory

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    exit 1
fi

# Check if directory path is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: No directory path provided${NC}"
    echo "Usage: $0 /path/to/directory"
    exit 1
fi

# Check if share name is provided
if [ -z "$2" ]; then
    echo -e "${RED}Error: No share name provided${NC}"
    echo "Usage: $0 /path/to/director sharename"
    exit 1
fi

SHARE_DIR="$1"
SHARE_NAME="$2"

# Check if directory exists, if not create it
if [ ! -d "$SHARE_DIR" ]; then
    echo -e "${YELLOW}Directory does not exist. Creating: $SHARE_DIR${NC}"
    mkdir -p "$SHARE_DIR"
fi

echo -e "${GREEN}Setting up Samba share for: $SHARE_DIR${NC}"

# Install Samba if not already installed
if ! command -v smbd &> /dev/null; then
    echo -e "${YELLOW}Samba is not installed. Installing...${NC}"
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y samba
    elif command -v yum &> /dev/null; then
        yum install -y samba
    elif command -v dnf &> /dev/null; then
        dnf install -y samba
    else
        echo -e "${RED}Error: Could not detect package manager. Please install Samba manually.${NC}"
        exit 1
    fi
fi

# Set directory permissions for full access
echo -e "${GREEN}Setting directory permissions...${NC}"
chmod 777 "$SHARE_DIR"
chown nobody:nogroup "$SHARE_DIR" 2>/dev/null || chown nobody:nobody "$SHARE_DIR" 2>/dev/null || true

# Set SELinux context if SELinux is enabled
if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
    echo -e "${GREEN}Setting SELinux context...${NC}"
    semanage fcontext -a -t samba_share_t "$SHARE_DIR(/.*)?" 2>/dev/null || true
    restorecon -R "$SHARE_DIR" 2>/dev/null || true
    setsebool -P samba_enable_home_dirs on 2>/dev/null || true
    setsebool -P samba_export_all_rw on 2>/dev/null || true
fi

# Backup existing smb.conf
if [ -f /etc/samba/smb.conf ]; then
    cp /etc/samba/smb.conf /etc/samba/smb.conf.backup.$(date +%Y%m%d_%H%M%S)
    echo -e "${GREEN}Backed up existing smb.conf${NC}"
fi

# Check if share already exists in smb.conf
if grep -q "^\[$SHARE_NAME\]" /etc/samba/smb.conf 2>/dev/null; then
    echo -e "${YELLOW}Warning: Share [$SHARE_NAME] already exists in smb.conf${NC}"
    echo -e "${YELLOW}Removing old configuration...${NC}"
    # Remove existing share configuration
    sed -i "/^\[$SHARE_NAME\]/,/^$/d" /etc/samba/smb.conf
fi

# Ensure guest access is enabled in global section
if ! grep -q "^[[:space:]]*map to guest[[:space:]]*=" /etc/samba/smb.conf; then
    sed -i '/^\[global\]/a \   map to guest = Bad User' /etc/samba/smb.conf
fi

# Add the share configuration to smb.conf
echo -e "${GREEN}Adding share configuration to /etc/samba/smb.conf...${NC}"
cat >> /etc/samba/smb.conf << EOF

[$SHARE_NAME]
   path = $SHARE_DIR
   browseable = yes
   writable = yes
   guest ok = yes
   guest only = yes
   read only = no
   create mask = 0777
   directory mask = 0777
   force user = rob
   force create mode = 0777
   force directory mode = 0777
   public = yes
EOF

# Test Samba configuration
echo -e "${GREEN}Testing Samba configuration...${NC}"
if testparm -s /etc/samba/smb.conf &>/dev/null; then
    echo -e "${GREEN}Samba configuration is valid${NC}"
else
    echo -e "${RED}Error: Invalid Samba configuration${NC}"
    testparm -s /etc/samba/smb.conf
    exit 1
fi

# Restart Samba service
echo -e "${GREEN}Restarting Samba service...${NC}"
if command -v systemctl &> /dev/null; then
    systemctl restart smbd 2>/dev/null || systemctl restart smb 2>/dev/null || true
    systemctl restart nmbd 2>/dev/null || true
    systemctl enable smbd 2>/dev/null || systemctl enable smb 2>/dev/null || true
    systemctl enable nmbd 2>/dev/null || true
else
    service smbd restart 2>/dev/null || service smb restart 2>/dev/null || true
    service nmbd restart 2>/dev/null || true
fi

# Open firewall ports if firewalld is active
if command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld; then
    echo -e "${GREEN}Opening Samba ports in firewall...${NC}"
    firewall-cmd --permanent --add-service=samba 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
fi

# Get server IP addresses
echo -e "\n${GREEN}=== Samba Share Setup Complete ===${NC}"
echo -e "${GREEN}Share name:${NC} $SHARE_NAME"
echo -e "${GREEN}Share path:${NC} $SHARE_DIR"
echo -e "${GREEN}Access:${NC} Guest (no password required)"
echo -e "${GREEN}Permissions:${NC} Read/Write for everyone"
echo ""
echo -e "${GREEN}Access the share from:${NC}"
echo "  Windows: \\\\$(hostname)\\$SHARE_NAME or \\\\<server-ip>\\$SHARE_NAME"
echo "  Linux:   smb://$(hostname)/$SHARE_NAME or smb://<server-ip>/$SHARE_NAME"
echo "  macOS:   smb://$(hostname)/$SHARE_NAME or smb://<server-ip>/$SHARE_NAME"
echo ""
echo -e "${GREEN}Server IP addresses:${NC}"
ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print "  " $2}' | cut -d'/' -f1
echo ""
echo -e "${YELLOW}Note: No password is required to access this share${NC}"
