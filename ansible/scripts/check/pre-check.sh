#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
HOST=""
USERNAME="root"
KEY_FILE=""
USE_PASSWORD=false

# Parse command line arguments
while getopts "h:k:u:p" opt; do
  case $opt in
    h) HOST="$OPTARG"
      ;;
    k) KEY_FILE="$OPTARG"
      ;;
    u) USERNAME="$OPTARG"
      ;;
    p) USE_PASSWORD=true
      ;;
    \?) echo "Invalid option -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Validate required parameters
if [ -z "$HOST" ]; then
  echo "Usage: $0 -h <host> -u <username> [-k <key_file> | -p]"
  exit 1
fi

if [ "$USE_PASSWORD" = false ] && [ -z "$KEY_FILE" ]; then
  echo "Either SSH key (-k) or password (-p) must be specified"
  exit 1
fi

# Function to run remote command
run_remote() {
  if [ "$USE_PASSWORD" = true ]; then
    sshpass -e ssh -o StrictHostKeyChecking=no "$USERNAME@$HOST" "$1"
  else
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$USERNAME@$HOST" "$1"
  fi
}

# Function to check system requirements
check_system() {
    echo -e "${YELLOW}Checking system requirements...${NC}"
    
    # Check OS
    OS_INFO=$(run_remote "cat /etc/os-release")
    if echo "$OS_INFO" | grep -q -E "ID=(ubuntu|debian)"; then
        echo -e "OS: ${GREEN}$(echo "$OS_INFO" | grep PRETTY_NAME | cut -d'"' -f2)${NC}"
    else
        echo -e "${RED}Error: This script only supports Ubuntu and Debian${NC}"
        exit 1
    fi

    # Check CPU
    CPU_CORES=$(run_remote "nproc")
    echo -e "CPU Cores: ${GREEN}$CPU_CORES${NC}"
    if [ "$CPU_CORES" -lt 2 ]; then
        echo -e "${RED}Warning: Minimum 2 CPU cores recommended${NC}"
    fi

    # Check Memory
    TOTAL_MEM=$(run_remote "free -m | awk '/^Mem:/{print \$2}'")
    echo -e "Total Memory: ${GREEN}${TOTAL_MEM}MB${NC}"
    if [ "$TOTAL_MEM" -lt 4096 ]; then
        echo -e "${RED}Warning: Minimum 4GB RAM recommended${NC}"
    fi

    # Check Disk Space
    ROOT_SPACE=$(run_remote "df -BG / | awk 'NR==2 {print \$4}' | sed 's/G//'")
    echo -e "Available Disk Space: ${GREEN}${ROOT_SPACE}GB${NC}"
    if [ "$ROOT_SPACE" -lt 20 ]; then
        echo -e "${RED}Warning: Minimum 20GB free space recommended${NC}"
    fi
}

# Function to check required packages
check_packages() {
    echo -e "\n${YELLOW}Checking required packages...${NC}"
    REQUIRED_PACKAGES="curl wget git software-properties-common apt-transport-https ca-certificates"
    
    for package in $REQUIRED_PACKAGES; do
        if run_remote "dpkg -l | grep -q '^ii  $package '"; then
            echo -e "$package: ${GREEN}Installed${NC}"
        else
            echo -e "$package: ${RED}Not installed${NC}"
        fi
    done
}

# Function to check ports
check_ports() {
    echo -e "\n${YELLOW}Checking required ports...${NC}"
    PORTS="80 443 3306 6379 9200 5672 8080 9090 9093 9100"
    
    for port in $PORTS; do
        if run_remote "netstat -tuln | grep -q ':$port '"; then
            echo -e "Port $port: ${RED}In use${NC}"
        else
            echo -e "Port $port: ${GREEN}Available${NC}"
        fi
    done
}

# Function to check Python for Ansible
check_python() {
    echo -e "\n${YELLOW}Checking Python for Ansible...${NC}"
    if run_remote "command -v python3 >/dev/null 2>&1"; then
        PYTHON_VERSION=$(run_remote "python3 --version")
        echo -e "Python3: ${GREEN}$PYTHON_VERSION${NC}"
    else
        echo -e "Python3: ${RED}Not installed${NC}"
        exit 1
    fi
}

# Main execution
echo -e "${YELLOW}=== Pre-installation System Check for Ansible Deployment ===${NC}\n"
check_system
check_packages
check_ports
check_python

echo -e "\n${YELLOW}=== System Check Complete ===${NC}" 