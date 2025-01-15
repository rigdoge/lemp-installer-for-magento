#!/bin/bash

# Common utility functions

# Error handling
trap_handler() {
    local exit_code=$?
    local line_number=$1
    echo "Error on line $line_number, exit code $exit_code"
    cleanup
    exit $exit_code
}

trap "trap_handler \${LINENO}" ERR

# Cleanup function
cleanup() {
    echo "Performing cleanup..."
    # Add cleanup tasks here
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]] && ! sudo -v &>/dev/null; then
        echo "This script must be run with sudo privileges"
        exit 1
    fi
}

# Load configuration
load_config() {
    local config_file=$1
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    else
        echo "Config file not found: $config_file"
        exit 1
    fi
}

# Backup function
backup_file() {
    local file=$1
    if [[ -f "$file" ]]; then
        cp "$file" "${file}.bak-$(date +%Y%m%d-%H%M%S)"
    fi
}
