#!/usr/bin/env bash

# SCRIPT_LIB_DIR="$(dirname "${BASH_SOURCE[0]}")"

NC=$'\e[0m' # No Color
RED=$'\e[31m'
GREEN=$'\e[32m'
BLUE=$'\e[34m'
ORANGE=$'\x1B[33m'
YELLOW='\033[1;33m'
BOLD=$'\033[1m'
UNDERLINE=$'\033[4m'

# Exception Handling
yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

# Displays Time in mins and seconds
function display_time {
    local T=$1
    local D=$((T/60/60/24))
    local H=$((T/60/60%24))
    local M=$((T/60%60))
    local S=$((T%60))
    (( D > 0 )) && printf '%d days ' $D
    (( H > 0 )) && printf '%d hours ' $H
    (( M > 0 )) && printf '%d minutes ' $M
    (( D > 0 || H > 0 || M > 0 )) && printf 'and '
    printf '%d seconds\n' $S
}

# Pretty Print
function pretty_print() {
  printf "%b" "$1"
}

# echo to std err
function echoStderr(){
    echo "$@" 1>&2
}

# time the action
function time_it(){
    action=$1
    shift 1
    start=$(date +%s)
    $action $@
    end=$(date +%s)
    runtime=$((end-start))
    pretty_print "\n${GREEN}$action ${UNDERLINE}Successful${NC} | $(display_time $runtime) ${NC}\n" 
}

# url - tool binary url
# destination - tool binary destination
# tool_check_cmd - tool check command
function install_tool(){
    url=$1
    destination=$2
    tool_check_cmd=$3
    export PATH=$GIT_BASE_PATH/bin:$PATH

    #wget -q https://github.com/goss-org/goss/releases/download/v0.3.20/goss-alpha-darwin-amd64 -O bin/goss && chmod +x bin/goss && goss --version 
    wget -q $url -O $destination
    chmod +x $destination
    $tool_check_cmd
    pretty_print "${GREEN}$tool installation Done !!! ${NC}" 
}

function pass(){
    pretty_print "\t${GREEN}✅ $1 ${NC}"
}

function fail(){
    pretty_print "\t${RED}❌ $1 ${NC}"
}

function warn(){
    pretty_print "\t${YELLOW}❗️ $1 ${NC}"
}

function line_separator(){
    pretty_print "\n${YELLOW}-------------------------------------------------------------------------------------------------------------------${NC}\n"
}

# check istioctl is installed
function install_istioctl(){
    # check istioctl is installed
    if [ -d $HOME/.istioctl ];then
        pretty_print "${YELLOW}istioctl is already installed. Skipping...${NC}\n"
    else 
        pretty_print "${YELLOW}installing istioctl.${NC}\n"
        try  curl -sL https://istio.io/downloadIstioctl | sh -
    fi
}

# Check if Mac
function is_mac(){ 
    if [[ $OSTYPE == "darwin"* ]]; then
        echo -e "${GREEN}Darwin OS Detected${NC}"
    else
        echo -e "${RED}Darwin OS is required to Run brew${NC}"
        exit 1
    fi
}

# Check if Docker Desktop is Running
function check_for_docker_desktop(){
    if [[ -n "$(docker info --format '{{.OperatingSystem}}' | grep 'Docker Desktop')" ]]; then
        echo -e "${GREEN}\nDocker Desktop found....${NC}"
    else
        echo -e "${RED}\nWARNING! Docker Desktop not installed:${NC}"
        echo -e "${YELLOW}  * Install docker desktop from <https://docs.docker.com/docker-for-mac/install/>\n${NC}"
        exit 1
    fi

}

# Get IP Address of Mac
function get_ip_mac(){
    ip=$(ifconfig en0 | grep inet | grep -v inet6 | cut -d ' ' -f2)
    echo "$ip"
}

# Get IP Address of Linux
function get_ip_linux(){
    ip=$(ip route get 8.8.8.8 | sed -n '/src/{s/.*src *\([^ ]*\).*/\1/p;q}')
    echo "$ip"
}

# Check IP is reachable
function ip_reachable(){
    ip=$1
    if [[ -n "$(dig +short $ip)" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Load Environment Variables fronm .env file
function load_env() {
  # Load environment variables from .env file
  set -a
  [ -f $GIT_BASE_PATH/.env ] && . $GIT_BASE_PATH/.env
  set +a
}

# Check if the machine has at least 4GB of RAM
function check_ram(){
    ram=$(sysctl hw.memsize | awk '{print $2}')
    if [ $ram -lt 4294967296 ]; then
        fail "${RED}${BOLD}Insufficient RAM${NC}"
        warn "${BLUE}Minimum RAM required is 4GB${NC}\n"
        return 1
    else 
        pass "${GREEN}${BOLD}RAM Check (RAM: >= 4 GB) - Passed${NC}\n"
        return 0
    fi
}

# Check if the machine has at least a quad-core processor
function check_processor(){
    processor=$(sysctl hw.ncpu | awk '{print $2}')
    if [ $processor -lt 4 ]; then
        fail "${RED}${BOLD}Insufficient Processor${NC}"
        warn "${BLUE}Minimum Processor required is a Quad-Core${NC}\n"
        return 1
    else 
        pass "${GREEN}${BOLD}Processor Check (CPU: >= 4 )- Passed${NC}\n"
        return 0
    fi
}

