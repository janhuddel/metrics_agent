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
            error "No releases found for repository ${REPO_OWNER}/${REPO_NAME}. Please create a release first."
        else
            error "Failed to fetch releases from GitHub API (HTTP ${http_code})"
        fi
    fi
    
    # Check if the response contains a tag_name field
    if ! echo "$json_body" | grep -q '"tag_name":'; then
        error "No releases found for repository ${REPO_OWNER}/${REPO_NAME}. Please create a release first."
    fi
    
    local latest_tag=$(echo "$json_body" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [[ -z "$latest_tag" ]]; then
        error "Failed to parse latest release tag from GitHub API response"
    fi
    
    echo "$latest_tag"
}

# Download and extract release
download_release() {
    local tag="$1"
    local download_url="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${tag}/metrics_agent.tar.gz"
    local temp_dir=$(mktemp -d)
    
    log "Downloading release ${tag}..."
    curl -L -o "${temp_dir}/metrics_agent.tar.gz" "$download_url" || error "Failed to download release"
    
    log "Extracting release..."
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

# Create configuration file
create_config() {
    log "Creating configuration file..."
    
    cat > "$CONFIG_DIR/config.exs" << 'EOF'
import Config

# Logger configuration - preserve standard_error for production compatibility
config :logger,
  level: :info

config :logger, :default_handler,
  config: [
    type: :standard_error
  ]

config :logger, :default_formatter,
  format: "$date $time [$level] [$metadata] $message\n",
  metadata: [:module]

# Demo module configuration
config :metrics_agent, :demo,
  enabled: true,
  interval: 1000,
  vendor: "demo"

# Tasmota module configuration
config :metrics_agent, :tasmota,
  enabled: true,
  mqtt_host: System.get_env("MQTT_HOST", "localhost"),
  mqtt_port: String.to_integer(System.get_env("MQTT_PORT", "1883")),
  discovery_topic: System.get_env("DISCOVERY_TOPIC", "tasmota/discovery/+/config")
EOF

    chown "$SERVICE_USER:$SERVICE_GROUP" "$CONFIG_DIR/config.exs"
    chmod 644 "$CONFIG_DIR/config.exs"
}

# Create environment file
create_environment() {
    log "Creating environment file..."
    
    cat > "/etc/metrics-agent/environment" << 'EOF'
# Metrics Agent Environment Configuration
# Edit these values according to your setup

# MQTT Configuration
MQTT_HOST=localhost
MQTT_PORT=1883
DISCOVERY_TOPIC=tasmota/discovery/+/config

# Application Environment
MIX_ENV=prod
EOF

    chown "$SERVICE_USER:$SERVICE_GROUP" "/etc/metrics-agent/environment"
    chmod 644 "/etc/metrics-agent/environment"
}

# Note: Environment file is used by Telegraf's inputs.execd, not a separate systemd service

# Main installation function
main() {
    log "Starting Metrics Agent installation..."
    
    check_root
    
    # Get latest release
    local latest_tag=$(get_latest_release)
    log "Latest release: ${latest_tag}"
    
    # Download and extract
    local temp_dir=$(download_release "$latest_tag")
    
    # Cleanup function
    cleanup() {
        log "Cleaning up temporary files..."
        rm -rf "$temp_dir"
    }
    trap cleanup EXIT
    
    # Install components
    #create_user
    #install_application "$temp_dir"
    #create_config
    #create_environment
    
    log "Installation completed successfully!"
    log ""
    log "Next steps:"
    log "1. Edit /etc/metrics-agent/environment to configure MQTT settings"
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
