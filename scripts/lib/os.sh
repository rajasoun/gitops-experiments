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
        pass "Darwin OS Detected\n"
    else
        fail "Darwin OS is required to Run brew\n"
        exit 1
    fi
}

# Query OS Type
function os_type(){
    local os
    case $OSTYPE in
        darwin*) os="Mac" ;;
        linux*) os="Linux" ;;
        msys*) os="Windows" ;;
        *) die "unknown: $OSTYPE" ;;
    esac
    echo "$os"
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
        fail "Insufficient Processor\n"
        warn "Minimum Processor required is a Quad-Core\n"
        return 1
    else 
        pass "Processor Check (CPU: >= 4 )- Passed$\n"
        return 0
    fi
}

# Check if the machine has at least 20GB of disk space
function check_disk_space(){
    disk_space=$(df -k / | awk '{print $4}' | tail -1)
    if [ $disk_space -lt 20971520 ]; then
        fail "Insufficient Disk Space\n"
        warn "Minimum Disk Space required is 20GB\n"
        return 1
    else 
        pass "Disk Space Check (Disk Space: >= 20 GB) - Passed\n"
        return 0
    fi
}

# Check if the machine has at least 2GB of swap space
function check_swap_space(){
    swap_space=$(sysctl vm.swapusage | awk '{print $3}' | tail -1)
    if [ $swap_space -lt 2147483648 ]; then
        fail "Insufficient Swap Space\n"
        warn "Minimum Swap Space required is 2GB\n"
        return 1
    else 
        pass "Swap Space Check (Swap Space: >= 2 GB) - Passed\n"
        return 0
    fi
}

# Check if docker desktop is running
function check_docker_desktop(){
    if [[ -n "$(docker info --format '{{.OperatingSystem}}' | grep 'Docker Desktop')" ]]; then
        pass "Docker Desktop Check - Passed\n"
        return 0
    else
        fail "Docker Desktop Check - Failed\n"
        warn "Docker Desktop is not running\n"
        return 1
    fi
}

# Check GitHub credentials using gh cli 
function check_gh_crendentials(){
    host=${1-github.com}    
    gh_auth_status=$(gh auth status --hostname $host > /dev/null 2>&1)
    if [[ $gh_auth_status -eq 0  ]]; then
        pass "GitHub Authentication Check - Passed\n"
        return 0
    else
        fail "GitHub Check - Failed\n"
        warn "GitHub credentials are not set\n"
        return 1
    fi
}

# Check AWS credentials using aws cli
function check_aws_credentials(){
    if [[ $(aws sts get-caller-identity) == *"arn:aws:iam"* ]]; then
        pass "AWS Authentication Check - Passed\n"
        return 0
    else
        fail "AWS Check - Failed\n"
        warn "AWS credentials are not set\n"
        return 1
    fi
}



