#!/bin/bash

# Metrics Agent Installation Script
# Follows Linux Filesystem Hierarchy Standard (FHS)

set -euo pipefail

# Configuration
REPO_OWNER="janhuddel"  # Update this with your GitHub username
REPO_NAME="metrics_agent"
INSTALL_DIR="/opt/metrics-agent"
CONFIG_DIR="/etc/metrics-agent"
LOG_DIR="/var/log/metrics-agent"
SERVICE_USER="telegraf"
SERVICE_GROUP="telegraf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
    fi
}

# Detect latest release
get_latest_release() {
    local latest_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
    local response=$(curl -s -w "%{http_code}" "$latest_url")
    local http_code="${response: -3}"
    local json_body="${response%???}"
    
    # Check if the API call was successful
    if [[ "$http_code" != "200" ]]; then
        if [[ "$http_code" == "404" ]]; then
            echo "No releases found for repository ${REPO_OWNER}/${REPO_NAME}. Please create a release first." >&2
            return 1
        else
            echo "Failed to fetch releases from GitHub API (HTTP ${http_code})" >&2
            return 1
        fi
    fi
    
    # Check if the response contains a tag_name field
    if ! echo "$json_body" | grep -q '"tag_name":'; then
        echo "No releases found for repository ${REPO_OWNER}/${REPO_NAME}. Please create a release first." >&2
        return 1
    fi
    
    local latest_tag=$(echo "$json_body" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [[ -z "$latest_tag" ]]; then
        echo "Failed to parse latest release tag from GitHub API response" >&2
        return 1
    fi
    
    echo "$latest_tag"
}

# Download and extract release
download_release() {
    local tag="$1"
    local download_url="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${tag}/metrics_agent.tar.gz"
    local temp_dir=$(mktemp -d)
    
    log "Downloading release ${tag}..." >&2
    curl -L -o "${temp_dir}/metrics_agent.tar.gz" "$download_url" || error "Failed to download release"
    
    log "Extracting release..." >&2
    tar -xzf "${temp_dir}/metrics_agent.tar.gz" -C "$temp_dir" || error "Failed to extract release"
    
    echo "$temp_dir"
}

# Create system user and group
create_user() {
    if ! id "$SERVICE_USER" &>/dev/null; then
        log "Creating user ${SERVICE_USER}..."
        useradd --system --no-create-home --shell /bin/false "$SERVICE_USER" || error "Failed to create user"
    else
        log "User ${SERVICE_USER} already exists"
    fi
}

# Install application
install_application() {
    local temp_dir="$1"
    
    log "Installing application to ${INSTALL_DIR}..."
    
    # Remove old installation if it exists
    if [[ -d "$INSTALL_DIR" ]]; then
        log "Removing old installation..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Create directories
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOG_DIR"
    
    # Copy application files
    cp -r "${temp_dir}/metrics_agent"/* "$INSTALL_DIR/"
    
    # Set ownership and permissions
    chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR"
    chown -R "$SERVICE_USER:$SERVICE_GROUP" "$LOG_DIR"
    chmod 755 "$INSTALL_DIR"
    chmod 755 "$INSTALL_DIR/bin"
    chmod 755 "$INSTALL_DIR/bin/metrics_agent"
}

# Note: No systemd service needed - metrics_agent runs under Telegraf's inputs.execd

# Note: Configuration is now handled via TOML files
# The main configuration file is /etc/metrics-agent/config.toml

# Create TOML configuration file
create_config() {
    log "Creating TOML configuration file..."
    
    cat > "/etc/metrics-agent/config.toml" << 'EOF'
# Metrics Agent Configuration
# Edit these values according to your setup

# Demo module configuration
[modules.demo]
enabled = true
interval = 1000
vendor = "demo"

# Tasmota module configuration
[modules.tasmota]
enabled = true
mqtt_host = "localhost"
mqtt_port = 1883
discovery_topic = "tasmota/discovery/+/config"
client_id = ""  # Leave empty for auto-generation

# Device-specific overrides for Tasmota module
# Uncomment and customize as needed:
# [modules.tasmota.devices."device1"]
# mqtt_host = "192.168.1.100"
# discovery_topic = "custom/device1/discovery/+/config"
EOF

    chown "$SERVICE_USER:$SERVICE_GROUP" "/etc/metrics-agent/config.toml"
    chmod 644 "/etc/metrics-agent/config.toml"
}

# Note: Environment file is used by Telegraf's inputs.execd, not a separate systemd service

# Main installation function
main() {
    log "Starting Metrics Agent installation..."
    
    check_root
    
    # Get latest release
    local latest_tag
    if ! latest_tag=$(get_latest_release 2>&1); then
        error "$latest_tag"
    fi
    log "Latest release: ${latest_tag}"
    
    # Download and extract
    local temp_dir=$(download_release "$latest_tag")
    
    # Cleanup function
    cleanup() {
        if [[ -n "${temp_dir:-}" ]]; then
            log "Cleaning up temporary files..."
            rm -rf "$temp_dir"
        fi
    }
    trap cleanup EXIT
    
    # Install components
    #create_user
    install_application "$temp_dir"
    create_config
    
    log "Installation completed successfully!"
    log ""
    log "Next steps:"
    log "1. Edit /etc/metrics-agent/config.toml to configure module settings"
    log "2. Add the Telegraf configuration to your telegraf.conf:"
    log ""
    log "[[inputs.execd]]"
    log "  command = [\"/opt/metrics-agent/bin/metrics_agent\", \"start\"]"
    log "  signal = \"STDIN\""
    log "  restart_delay = \"10s\""
    log "  data_format = \"influx\""
    log ""
    log "3. Restart Telegraf: systemctl restart telegraf"
    log "4. Check Telegraf status: systemctl status telegraf"
    log "5. View logs: journalctl -u telegraf -f"
}

# Run main function
main "$@"
