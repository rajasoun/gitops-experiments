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

# Function : Main function
# Description : 
#   Accepts an option as a command-line argument. 
#   The option is passed to the script when it is executed, and it is stored in the opt variable and 
#   converts the option to lowercase using the tr command and stores the result in the choice variable.
#   Uses a case statement to handle the different options:
#   1. If the option is "stdout", the script will call the print_tabular function, this function will take the output of get_env_in_all_namespaces and format it in tabular format using one of the alternatives you want (awk, cut, sed.. etc)
#   2. If the option is "file", the script will call the get_env_in_all_namespaces function and redirect its output to a file named "env_vars.csv"
#   3. If no option is provided, or an invalid option is provided, the script will print usage instructions and a list of valid options to the terminal.


# Function : stdout option
function print_tabular_output() {
    local result=$(get_env_in_all_namespaces)
    # if column is available use it
    if command -v column &> /dev/null; then
        # echo "$result" | awk '{if (NR==1) {print "\033[32m" $0 "\033[39m"} else {print}}' | column -t -s ','
        echo "$result" | column -t -s ','
    else
        #get_env_in_all_namespaces | awk -F, '{printf "%-20s %-20s %-20s %-20s \n", $1, $2, $3, $4}'
        echo "$result" | sed 's/,/\t/g'
    fi
}

# Function : file option
function write_to_file() {
    get_env_in_all_namespaces > env_vars.csv
}

# Function : usage
function usage() {
    echo "${RED}Usage: $0 < stdout | file >${NC}"
    cat <<-EOF
Commands:
---------
stdout        -> Prints the output to stdout  
file          -> Prints the output to a file 
EOF
}

# Function : Main function
function main(){
    opt="$1"
    choice=$( tr '[:upper:]' '[:lower:]' <<<"$opt" )
    case $choice in
        stdout)print_tabular_output;;
        file)write_to_file;;
        *);;
    esac
}

main $@
