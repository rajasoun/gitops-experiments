#!/usr/bin/env bash

# color formatting
NC=$'\e[0m' # No Color
RED=$'\e[31m'
GREEN=$'\e[32m'
BLUE=$'\e[34m'
ORANGE=$'\x1B[33m'
YELLOW='\033[1;33m'
BOLD=$'\033[1m'
UNDERLINE=$'\033[4m'

# Function: Print line separator
function print_line_separator(){
    printf "\n${YELLOW}-------------------------------------------------------------------------------------------------------------------${NC}\n"
}

# Function: Pretty print
function pretty_print() {
    local text=$1
    local color=$2
    printf "${color}%b${NC}" "$text"
}
# Function: Get env variables from a deployment in a specific namespace
function get_env_vars() {
    local namespace=$1
    local deployment=$2
    kubectl get deploy ${deployment} -n ${namespace} -o jsonpath='{.spec.template.spec.containers[*].env}' | jq -r '.[] | "\(.name)=\(.value)"'
}

# Function : Get env variables from all deployments in a specific namespace
function get_env_in_namespace() {
    local namespace=$1
    local deployments=$(kubectl get deploy -n ${namespace} -o jsonpath='{.items[*].metadata.name}')
    for deployment in ${deployments}; do
        env_vars=$(get_env_vars ${namespace} ${deployment})
        for env in ${env_vars}; do
            key=$(echo ${env} | cut -d'=' -f1)
            value=$(echo ${env} | cut -d'=' -f2)
            echo "${namespace},${deployment},${key},${value}"
        done
    done
}

# Function : Get env variables from all deployments in all namespaces
function get_env_in_all_namespaces() {
    echo "Namespace,Deployment,Key,Value"
    local namespaces=$(kubectl get ns -o jsonpath='{.items[*].metadata.name}')
    for namespace in ${namespaces}; do
        get_env_in_namespace ${namespace}
    done
}

# Function : Print in Tabular format
function print_tabular() {
    #  check if column is installed
    if [ command -v column &> /dev/null ];then
        get_env_in_all_namespaces | column -t -s ','
    else 
        get_env_in_all_namespaces | sed 's/,/\t/g'
    fi
}


opt="$1"
choice=$( tr '[:upper:]' '[:lower:]' <<<"$opt" )
case $choice in
    stdout)print_tabular;;
    file)get_env_in_all_namespaces > env_vars.csv;;
    *)
    echo "${RED}Usage: $0 < stdout | file >${NC}"
cat <<-EOF
Commands:
---------
stdout        -> Prints the output to stdout  
file          -> Prints the output to a file 
EOF
    ;;
esac