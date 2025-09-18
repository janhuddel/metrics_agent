#!/bin/bash
# Wrapper script for metrics_agent that loads environment configuration
# This script automatically loads environment variables from /etc/metrics-agent/environment
# and starts the metrics_agent application.

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

# Load environment file if it exists
if [ -f "/etc/metrics-agent/environment" ]; then
    echo "Loading environment from /etc/metrics-agent/environment" >&2
    set -a  # Automatically export all variables
    source /etc/metrics-agent/environment
    set +a  # Turn off automatic export
else
    echo "Warning: /etc/metrics-agent/environment not found, using defaults" >&2
fi

# Set default MIX_ENV if not set
export MIX_ENV="${MIX_ENV:-prod}"

# Start the application
exec "$BINARY_PATH" start