#!/usr/bin/env bash

# Function: Get env variables from a deployment in a specific namespace
# Description:
#   Given a namespace and a deployment, this function retrieves the environment variables of the 
#   containers in that deployment. It uses the kubectl command to get the deployment in JSON format, 
#   then uses jsonpath to extract the environment variables. 
#   The jq command is used to format the output as name=value pairs, one per line.
# Parameters:
#   $1 -> namespace
#   $2 -> deployment
function get_env_vars() {
    local namespace=$1
    local deployment=$2
    kubectl get deploy ${deployment} -n ${namespace} -o jsonpath='{.spec.template.spec.containers[*].env}' | jq -r '.[] | "\(.name)=\(.value)"'
}

# Function : Get env variables from all deployments in a specific namespace
# Description:
#   Given a namespace, this function retrieves the environment variables for all deployments in that namespace. 
#   It first uses kubectl to get the names of all deployments in the namespace, then loops through them, calling get_env_vars for each deployment. 
#   For each environment variable, it uses cut command to extract the key and value and prints them as a comma separated string in the format 
#   "Namespace,Deployment,Key,Value".
# Parameters:
#   $1 -> namespace
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
# Description:
#    Retrieves the environment variables for all deployments in all namespaces. 
#   It first uses kubectl to get the names of all namespaces, then loops through them, calling get_env_in_namespace for each namespace.
function get_env_in_all_namespaces() {
    echo "Namespace,Deployment,Key,Value"
    local namespaces=$(kubectl get ns -o jsonpath='{.items[*].metadata.name}')
    for namespace in ${namespaces}; do
        get_env_in_namespace ${namespace}
    done
}

# Function : stdout option
# Description:
#   Invokes get_env_in_all_namespaces and formats the output as tabular format. 
#   It checks if the column command is available, if yes, it pipes the output to column command, otherwise, it uses sed command to replace commas with tabs.
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

# Function : Write to file the output
# Description:
#   This function calls get_env_in_all_namespaces and writes the output to a file named env_vars.csv
function write_to_file() {
    # check if the .report directory exists, if not, create it
    if [ ! -d .report ]; then
        mkdir .report
    fi
    get_env_in_all_namespaces > .report/env_vars.csv
}

# Function : usage
# Description:
#   Prints usage instructions and a list of valid options to the terminal.
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
# Description : 
#   Accepts an option as a command-line argument. 
#   The option is passed to the script when it is executed, and it is stored in the opt variable and 
#   converts the option to lowercase using the tr command and stores the result in the choice variable.
#   Uses a case statement to handle the different options:
#   1. If the option is "stdout", the script will call the print_tabular function, this function will take the output of get_env_in_all_namespaces and format it in tabular format using one of the alternatives you want (awk, cut, sed.. etc)
#   2. If the option is "file", the script will call the get_env_in_all_namespaces function and redirect its output to a file named "env_vars.csv"
#   3. If no option is provided, or an invalid option is provided, the script will print usage instructions and a list of valid options to the terminal.
# Parameters:
#   $1 -> option
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
