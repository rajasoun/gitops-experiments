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

# Pretty Print
function pretty_print() {
  printf "%b" "$1"
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

# echo to std err
function echoStderr(){
    echo "$@" 1>&2
}

# check if command installed via brew 
function check_brew_packages() {
    PACKAGE_LIST=($(grep -v "^#\|^$" iaac/prerequisites/local/Brewfile | awk '{print $2}' |  tr -d '"'))
    LABEL=$1
    echo -e "\n🧪 Testing $LABEL"
    brew list --version $PACKAGE_LIST[@]
    if [  $?  ];then
        echo -e "✅ $LABEL check passed.\n"
        return 0
    else
        echoStderr "❌ $LABEL check failed.\n"
        FAILED+=("$LABEL")
        return 1
    fi
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


function ip_reachable(){
    ip=$1
    if [[ -n "$(dig +short $ip)" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

function init_lb_env(){
    IP=$(kubectl --namespace istio-system get svc istio-ingressgateway  --output jsonpath="{.status.loadBalancer.ingress[0].ip}")
    HOSTNAME=$(kubectl --namespace istio-system get svc istio-ingressgateway --output jsonpath="{.status.loadBalancer.ingress[0].hostname}")

    if [[ $(ip_reachable $IP) == "false" ]]; then
        pretty_print "${YELLOW}IP $IP is not reachable.Switching to Local from .env\n${NC}"
        export $(grep -v "^#\|^$" .env | envsubst | xargs)
        export INGRESS_HOST_IP=$(dig +short $INGRESS_HOSTNAME)
        export BASE_HOST=$INGRESS_HOST_IP.nip.io
        pretty_print "${GREEN} INGRESS_HOSTNAME : $INGRESS_HOSTNAME | BASE_HOST : $BASE_HOST \n${NC}"
    fi
}

function load_env () {
  # Load environment variables from .env file
  set -a
  [ -f .env ] && . .env
  set +a
}

function pass(){
    pretty_print "\t${GREEN}✅ $1 ${NC}"
}

function fail(){
    pretty_print "\t${RED}❌ $1 ${NC}"
}