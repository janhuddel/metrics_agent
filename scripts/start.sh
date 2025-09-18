#!/bin/bash
# Wrapper script for metrics_agent that uses TOML configuration
# This script starts the metrics_agent application which loads configuration
# from /etc/metrics-agent/config.toml automatically.

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
BINARY_PATH="$APP_DIR/bin/metrics_agent"

# Check if the binary exists
if [ ! -f "$BINARY_PATH" ]; then
    echo "Error: metrics_agent binary not found at $BINARY_PATH" >&2
    exit 1
fi

# Check if TOML configuration file exists
if [ -f "/etc/metrics-agent/config.toml" ]; then
    echo "Configuration will be loaded from /etc/metrics-agent/config.toml" >&2
else
    echo "Warning: /etc/metrics-agent/config.toml not found, using defaults" >&2
fi

# Set default MIX_ENV
export MIX_ENV="${MIX_ENV:-prod}"

# Start the application
exec "$BINARY_PATH" start