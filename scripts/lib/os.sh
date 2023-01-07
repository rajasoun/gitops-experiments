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

########### Public Functions ###########

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

# check if command installed via brew 
function check_brew_packages() {
    GIT_BASE_PATH=$(git rev-parse --show-toplevel)
    PACKAGE_LIST=($(grep -v "^#\|^$" $GIT_BASE_PATH/local-dev/iaac/prerequisites/local/Brewfile | awk '{print $2}' |  tr -d '"'))
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

#  Initialize Load Balancer Env
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

# Load Environment Variables fronm .env file
function load_env() {
  # Load environment variables from .env file
  set -a
  [ -f $GIT_BASE_PATH/.env ] && . $GIT_BASE_PATH/.env
  set +a
}


# List Ingress
function list_ingress(){
     HOST="$1"
     echo -e "HOST PATH NAMESPACE SERVICE PORT INGRESS REWRITE"
     echo -e "---- ---- --------- ------- ---- ------- -------"
     kubectl get --all-namespaces ingress -o json | \
        jq -r '.items[] | . as $parent | .spec.rules | select(length > 0) | .[] | select(.host==$ENV.HOST) | .host as $host | .http.paths[] | ( $host + " " + .path + " " + $parent.metadata.namespace + " " + .backend.service.name + " " + (.backend.service.port.number // .backend.service.port.name | tostring) + " " + $parent.metadata.name + " " + $parent.metadata.annotations."nginx.ingress.kubernetes.io/rewrite-target")' | \
        sort | column -s\  -t
}

# Watch Pods in a namespace
function watch_pods_in_namespace(){
    NAMESPACE="$1"
    # kubectl get pods -n "$NAMESPACE" -w
    watch kubectl -n"$NAMESPACE" get pods
}

# tail logs in a namespace
function tail_logs_in_namespace(){
    NAMESPACE="$1"
    POD="$2"
    CONTAINER="$3"
    #kubectl -n "$NAMESPACE" logs -f "$POD" "$CONTAINER"
    stern -n "$NAMESPACE" --exclude-container istio-proxy .
}

# wait till all pods are ready
function wait_till_all_pods_are_ready(){
    NAMESPACE="$1"
    kubectl wait -n "$NAMESPACE" --for=condition=ready pods --all --timeout=120s
}

# print Gateway URL 
function print_gateway_url(){
    export GATEWAY_HOST=$(kubectl -n istio-system get service istio-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    export GATEWAY_PORT=$(kubectl -n istio-system get service istio-gateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
    export SECURE_GATEWAY_PORT=$(kubectl -n istio-system get service istio-gateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
    export GATEWAY_URL=$GATEWAY_HOST:$GATEWAY_PORT
    pretty_print "${GREEN}Gateway URL : http://$GATEWAY_HOST:$GATEWAY_PORT${NC}\n"
}

# list all the istio resources
function list_istio_resources(){
    pretty_print "${YELLOW}Listing all the Istio resources${NC}\n"
    kubectl get all -n istio-system
    line_separator
    pretty_print "${YELLOW}Listing Istio Gateway${NC}\n"
    kubectl get gateways.networking.istio.io -A
    line_separator
    pretty_print "${YELLOW}Listing Istio VirtualServices${NC}\n"
    kubectl get virtualservices.networking.istio.io -A
    line_separator
}


# kubeshark hub 
function kubeshark_hub(){
    local filter="timestamp >= now()"
    exlude_health_probes=("/health" "/healthz" "/ready" "/readyz" "/live" "/livez" "/healthz/ready")
    for path in "${exlude_health_probes[@]}"; do
        filter="$filter and request.path != \"$path\""
    done
    exclude_flux_probes=("" "source-controller.flux-system" "weave-gitops.flux-system" "notification-controller.flux-system")
    for path in "${exclude_flux_probes[@]}"; do
        filter="$filter and dst.name  != \"$path\""
    done
    pretty_print "${BLUE}$filter${NC}"
    url_encoded_filter=$(curl -s -w '%{url_effective}\n' -G / --data-urlencode "=$filter" | cut -c 3-)
    open -a "Google Chrome" "http://localhost:8899?q=$url_encoded_filter"
}

# flux reconcile 
function flux_reconcile(){
    names=("infra-controllers" "infra-configs" "istio-system" "istio-gateway" "dashboard" "apps")
    for name in "${names[@]}"; do
        pretty_print "\n${BLUE}Reconciling $name${NC}\n"
        flux reconcile kustomization "$name" --with-source && pass "Reconciled $name\n" || fail "Failed to reconcile $name\n"
        line_separator
    done
}

# install Brewfile by directory name 
function brew_install(){
    local app="$1"
    local directory="$GIT_BASE_PATH/local-dev/iaac/prerequisites/local"
    local brewfile="$directory/$app/Brewfile"

    if [ -f "$brewfile" ]; then
        pretty_print "${BLUE}Installing Brewfile for $app ${NC}\n"
        pretty_print "Brewfile -> $brewfile\n"
        brew bundle --file="$brewfile"
    else
        pretty_print "${RED}Brewfile not found for $app ${NC}\n"
        pretty_print "Brewfile -> $brewfile\n"
    fi
}

# uninstall Brewfile by directory name 
function brew_uninstall(){
    local app="$1"
    GIT_BASE_PATH=$(git rev-parse --show-toplevel)
    local brewfile="$GIT_BASE_PATH/local-dev/iaac/prerequisites/local/$app/Brewfile"
    if [ -f "$brewfile" ]; then
        pretty_print "${BLUE}Uninstalling Brewfile for $app ${NC}\n"
        pretty_print "Brewfile -> $brewfile\n"
        rm -fr /tmp/Brewfile
        cat  $GIT_BASE_PATH/local-dev/iaac/prerequisites/global/Brewfile > /tmp/Brewfile
        echo -e "\n" >> /tmp/Brewfile
        cat $GIT_BASE_PATH/local-dev/iaac/prerequisites/local/Brewfile >> /tmp/Brewfile
        brew bundle --file /tmp/Brewfile cleanup --force
        rm -fr /tmp/Brewfile
    else
        pretty_print "${RED}Brewfile not found for $app ${NC}\n"
        pretty_print "Brewfile -> $brewfile\n"
    fi
}

function check_brew_drift(){
    brew_integrity=$(brew list --version | sha256sum | awk '{print $1}')
    if [ $(cat "${GIT_BASE_PATH}/.github/.setup" | grep -c $brew_integrity) = 1 ];then
        echo -e "${GREEN}\nDrift Check - Passsed${NC}"
        echo -e "   ${GREEN}No Installation(s) found outside of Automation using Homebrew${NC}\n"
        return 0
    else
        echo -e "${RED}\nDrfit Check - Failed${NC}\n"
        echo -e "   ${ORGANGE}Installation(s) found outside of Automation using Homebrew${NC}\n"
        return 1
    fi
}

function audit_trail(){
    brew_integrity=$(brew list --version | sha256sum | awk '{print $1}')
    echo "Installed Packages (via brew) Integrity: $brew_integrity" > ${GIT_BASE_PATH}/.github/.setup
}

# start port forwarding for a service
# Parameters:
#   $1 - namespace - e.g. "httpd-app"
#   $2 - service_name - e.g. "httpd"
#   $3 - port_mapping - e.g. "8080:80"
function port_forward(){
  local namespace="$1"
  local service_name="$2"
  local port_mapping="$3"

  # check parameters are not empty
    if [ -z "$namespace" ] || [ -z "$service_name" ] || [ -z "$port_mapping" ]; then
        echo -e "${RED}${BOLD}Invalid parameters${NC}"
        echo -e "${BLUE}Usage: scripts/wrapper.sh run port_forward  <namespace> <service_name> <port_mapping>${NC}"
        echo -e "${BOLD}Example:${NC} scripts/wrapper.sh run port_forward ingress-nginx ingress-nginx-controller 8080:80"
        return 1
    fi

  pretty_print "${YELLOW}Starting Port Forward${NC}\n"
  #kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80 &> "./logs/$service_name.log" &
  kubectl port-forward "--namespace=$namespace" "service/$service_name" "$port_mapping" &> "./logs/$service_name.log" &
  server_pid=$!
  echo "pid=$server_pid" > "./logs/pids/$service_name.pid"
  pretty_print "${GREEN}Port Forward Started with pid=$server_pid${NC}\n"
}

# stop port forwarding for a service
# Parameters:
#   $1 - service_name - e.g. "httpd"
function stop_port_forward(){
    service_name="$1"
    if [ -z "$service_name" ]; then
        echo -e "${RED}${BOLD}Invalid parameters${NC}"
        echo -e "${BLUE}Usage: scripts/wrapper.sh run stop_port_forward <service_name>${NC}"
        echo -e "${BOLD}Example:${NC} scripts/wrapper.sh run stop_port_forward ingress-nginx-controller"
        return 1
    fi
    source "./logs/pids/$service_name.pid"
    pretty_print "${YELLOW}Stopping Port Forward${NC}\n"
    kill -9 $pid
    rm -fr "./logs/pids/$service_name.pid"
    rm -fr "./logs/$service_name.log"
    pretty_print "${GREEN}Port Forward Stopped${NC}\n"
}

# print docs pointer to get started 
function docs(){
    echo -e "\n"
    pretty_print "${GREEN}${BOLD}Getting Started Guide${NC}"
    line_separator
    pretty_print "${BLUE}1. GitHub URL - https://github.com/rajasoun/gitops-experiments/ ${NC}\n"
    line_separator
    echo -e "\n"
}

# # install istio if not installed
# function install_istio_if_not(){
#     # Check if istio is installed
#     if ! kubectl get namespace istio-system > /dev/null 2>&1; then
#         echo -e "${RED}Istio is not installed. Auto Installing istio before installing the app${NC}"
#         scripts/service-mesh/istio.sh setup 
#         export PATH=$HOME/.istioctl/bin:$PATH 
#     fi
# }
