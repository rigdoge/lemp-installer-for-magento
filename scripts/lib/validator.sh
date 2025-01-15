#!/bin/bash

# System requirement validation functions

# Check system memory
check_memory() {
    local required_mem=$1
    local total_mem=$(free -m | awk "/^Mem:/{print \$2}")
    if (( total_mem < required_mem )); then
        echo "Insufficient memory: ${total_mem}MB available, ${required_mem}MB required"
        return 1
    fi
    return 0
}

# Check disk space
check_disk_space() {
    local required_space=$1
    local available_space=$(df -BG / | awk "NR==2 {print \$4}" | sed "s/G//")
    if (( available_space < required_space )); then
        echo "Insufficient disk space: ${available_space}GB available, ${required_space}GB required"
        return 1
    fi
    return 0
}

# Check port availability
check_port() {
    local port=$1
    if netstat -tuln | grep -q ":${port} "; then
        echo "Port ${port} is already in use"
        return 1
    fi
    return 0
}

# Validate PHP version
check_php_version() {
    local required_version=$1
    if ! command -v php &>/dev/null; then
        echo "PHP is not installed"
        return 1
    fi
    local current_version=$(php -r "echo PHP_VERSION;")
    if [[ "$current_version" < "$required_version" ]]; then
        echo "PHP version $current_version is lower than required version $required_version"
        return 1
    fi
    return 0
}
