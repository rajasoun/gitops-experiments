#!/usr/bin/env bash

GIT_BASE_PATH=$(git rev-parse --show-toplevel)

# Function: log
# Description:
#   Logs a message to stdout with a specified color
# Parameters:
#   $1 -> message
#   $2 -> color code (e.g. \033[31m for red)
function log() {
    local message=$1
    local color=$2
    local NC='\033[0m'
    echo -e "${color}${message}${NC}"
}

# Function: info
# Description:
#   Logs an info message to stdout in blue
# Parameters:
#   $1 -> message
function info() {
    local BLUE="\033[34m"
    log "$1" "${BLUE}"
}

# Function: warn
# Description:
#   Logs a warning message to stdout in yellow
# Parameters:
#   $1 -> message
function warn() {
    local YELLOW="\033[33m"
    log "$1" "${YELLOW}"
}

# Function: error
# Description:
#   Logs an error message to stderr in red
# Parameters:
#   $1 -> message
function error() {
    local RED="\033[31m"
    log "$1" "${RED}" >&2
}

# Function: success
# Description:
#   Logs a success message to stdout in green
# Parameters:
#   $1 -> message
function success() {
    local GREEN="\033[32m"
    log "$1" "${GREEN}"
}


### Exception Handling ###

# Function: Prints Error Message to stderr
# Description:
#   Given a message, this function prints it to stderr.
# Parameters:
#   $1 -> message
function print_error() {
    echo "$0: $*" >&2
}

# Function: Returns 1 with an error message
# Description:
#   Given a command, this function returns 1 with an error message.
# Parameters:
#   $1 -> command
function return_on_error() {
    error "Command: [$1] Failed."
    return 1
}

# Function: Execute command and return 1 with an error message if it fails
# Description:
#   Given a command, this function executes it and return 1 with an error message if it fails.
# Parameters:
#   $@ -> command
function try() {
    "$@" || return_on_error "$*" 
}


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

# Function : Fileter report file by amazon endpoints
# Description:
#   This function filters the report file by amazon endpoints
function filter_amazon_endpoints() {
    local report_file=".report/env_vars.csv"
    local aws_endpoints_report_file=".report/amazon_endpoints.csv"
    local aws_endpoints_count=$(cat $report_file | grep -i amazon | grep ".com" | wc -l)
    if [ $aws_endpoints_count -gt 0 ]; then
        echo "Namespace,Deployment,Key,Value" > $aws_endpoints_report_file
        cat $report_file | grep -i amazon | grep ".com" >> $aws_endpoints_report_file
    else 
        warn "AWS Endpoints : $aws_endpoints_count Found."
        error "Check kubetx if multiple clusters are configured and the current context is set to the correct cluster."
    fi
}

# Function : Write to file the output
# Description:
#   This function calls get_env_in_all_namespaces and writes the output to a file named env_vars.csv
function write_to_file() {
    local report_file=".report/env_vars.csv"
    # check if the .report directory exists, if not, create it
    if [ ! -d .report ]; then
        mkdir .report
    fi
    get_env_in_all_namespaces > $report_file
    info "Report Generation Done. Check .report directory for the report files"
    filter_amazon_endpoints
}

# Function : Retrieve a list of all Kubernetes resources in the cluster.
# Description:
#  The kubectl api-resources command is used to get the list of all resources types available in the cluster and 
#  the kubectl get command is used to get the resources. 
#   --namespaced=false option is used to get the resources that are not namespaced 
#   --verbs=list is used to get the list of resources. 
#   -o=name option is used to format the output as "<resource_type>/<resource_name>" for easy readability. 
function get_cluster_resources() {
    # kubectl get -o=name pvc,configmap,serviceaccount,secret,ingress,service,deployment,statefulset,hpa,job,cronjob
    # resource_types=(pvc configmap serviceaccount secret ingress service deployment statefulset hpa job cronjob)
    # kubectl get "${resource_types[@]}" -o=name
    resources=$(kubectl api-resources --namespaced=false --verbs=list -o=name)
    kubectl get "${resources[@]}" -o=name
}

# Function : Export the YAML files from a cluster for a specific resource
# Description:
#   Exports the yaml representation of a specified Kubernetes resource to a file. 
#   The function takes one argument, resource_name, which is the name of the resource to be exported. 
#   Sets a local variable, resources_path, to a predefined path ($GIT_BASE_PATH/.resources), where the exported yaml files will be saved.
#   Creates a subdirectory within resources_path that corresponds to the resource type (if it exists) using mkdir -p "$resources_path/$(dirname $resource_name)". 
#   This allows for the exported yaml files to be organized by resource type, making it easier to find specific resources.
#   Use kubectl command to retrieve the yaml representation of the specified resource using the kubectl get -o=yaml $resource_name command. 
#   This command returns the yaml representation of the resource in the command line output. 
#   The output is then redirected to a file located at "$resources_path/$resource_name.yaml" using > operator, creating a new file or overwrite the file if it already exists.
# Parameters:
#   resource_name: The name of the resource to be exported.
function export_resource_yaml() {
    local resources_path="$GIT_BASE_PATH/.resources"
    local resource_name=$1
    mkdir -p "$resources_path/$(dirname $resource_name)"
    info "Generating YAML files for resource=$resource\n"
    kubectl get -o=yaml $resource_name > "$resources_path/$resource_name.yaml"
}

# Function : Export the YAML files from a cluster
# Description:
#   Export the YAML representation of resources in a cluster. 
#   Gets a list of resources in the cluster using the function "get_cluster_resources", and then iterates through each resource in the list. 
#   For each resource, it then calls the function "export_resource_yaml" and passes the resource as an argument, 
#   which exports the YAML representation of the resource to a file.
function export_yaml_from_cluster(){
    local cluster_resources=$(get_cluster_resources)
    for resource in $cluster_resources
    do
        export_resource_yaml $resource
    done
}


# Function : Get helm releases from a cluster
# Description:
#   This function gets the list of Helm releases in the cluster using the helm list -q command.
function get_helm_releases() {
    # check the time stamp of the file creation for $GIT_BASE_PATH/.resources/helm_releases.txt
    # if the file is older than 1 day, then delete the file and create a new one
    # else, use the existing file
    if [ -f $GIT_BASE_PATH/.resources/helm_releases.txt ]; then
        local file_creation_time=$(stat -c %Y $GIT_BASE_PATH/.resources/helm_releases.txt)
        local current_time=$(date +%s)
        local time_diff=$(($current_time - $file_creation_time))
        if [ $time_diff -gt 86400 ]; then
            info "Helm releases file is older than 1 day. Deleting the file and creating a new one."
            rm $GIT_BASE_PATH/.resources/helm_releases.txt
            helm list -q > $GIT_BASE_PATH/.resources/helm_releases.txt
        fi
    else
        helm list -q > $GIT_BASE_PATH/.resources/helm_releases.txt
    fi
    cat $GIT_BASE_PATH/.resources/helm_releases.txt
}

# Function: Get helm templates from a release
# Description:
#   This function gets the list of templates from a release using the helm get all $1 command.
#   The helm get all $1 command returns the list of templates in the release.
#   The grep templates command filters the output to only include the templates.
#   The awk '{print $3}' command prints the third column of the output, which is the name of the template.
function get_templates() {
    local release=$1
    helm get all $release | grep templates | awk '{print $3}'
}

# Function: Get helm manifest content from a release
# Description: 
#   Creates a directory called "manifests" within the "$resources_path/helm/$release" directory and 
#   Uses the grep and awk command to find the line numbers of each manifest in the "all.yaml" file. 
#   Then it uses the sed command to extract the content between these line numbers and write it to the corresponding manifest file.
# Parameters:
#   release: The name of the release
#   resources_path: The path to the resources directory
function extract_manifest_content() {
  local release=$1
  local resources_path=$2
  local template=$3
  local manifest_file=$(basename $template)
  local start_line_number=$(grep -n "$template" "$resources_path/$release/manifest.yaml" | awk -F: '{print $1}')
  local end_line_number=$(grep -n "templates/" "$resources_path/$release/manifest.yaml" | awk -F: '{print $1}' | grep -A1 $start_line_number | tail -1)
  # subtrcat 1 from the end_line_number to exclude the line with the next template
  end_line_number=$(($end_line_number - 1))
  sed -n "$start_line_number,$end_line_number p" "$resources_path/$release/manifest.yaml" > "$resources_path/$release/manifests/$manifest_file"
}

# Function: Split helm manifest by resource type
# Description:
#   This function splits the manifest file into separate files based on the resource type.
#   The function takes two arguments, release and resources_path.
#   The release argument is the name of the release.
#   The resources_path argument is the path to the resources directory.
# Parameters:
#   release: The name of the release
#   resources_path: The path to the resources directory
function split_helm_manifest_by_resource_type() {
    local release=$1
    local resources_path=$2
    mkdir -p "$resources_path/$release/manifests"
    for template in $(get_templates $release)
    do
        extract_manifest_content $release $resources_path $template
    done
}

# Function : Export helm Chart.yaml file from a cluster along with the values.yaml file and the reconstructed templates directory
# Description:
#   This function exports the helm Chart.yaml file from a cluster along with the values.yaml file and the reconstructed templates directory.
#   The function takes one argument, release, which is the name of the release to be exported.
#   Sets a local variable, resources_path, to a predefined path ($GIT_BASE_PATH/.resources), where the exported yaml files will be saved.
#   Creates a subdirectory within resources_path that corresponds to the release name (if it exists) using mkdir -p "$resources_path/helm/$release".
#   This allows for the exported yaml files to be organized by release name, making it easier to find specific releases.
#   Use helm get all $release command to retrieve the yaml representation of the specified release.
#   This command returns the yaml representation of the release in the command line output.
#   The output is then redirected to a file located at "$resources_path/helm/$release/$release.yaml" using > operator, 
#   creating a new file or overwrite the file if it already exists.
function export_helm_chart_for_release() {
    local resources_path="$GIT_BASE_PATH/.resources/helm"
    local release=$1
    mkdir -p "$resources_path/$release"
    # check when realease was last updated and 
    # compare it to the time the file $resources_path/$release/all.yaml was last updated
    # if the file is older than the release, then delete the file and create a new one
    
    # info "\nExporting Helm all for release : $release"
    # helm get all $release > "$resources_path/$release/all.yaml"
    info "Exporting Helm manifest for release : $release"
    helm get manifest $release > "$resources_path/$release/manifest.yaml"
    info "Exporting Helm manifest values for release : $release"
    helm get values $release > "$resources_path/$release/values.yaml"

    # info "Spliting manifest for release : $release"
    # split_helm_manifest_by_resource_type $release $resources_path

    info "Building kustomization.yaml for release : $release"
    cp $GIT_BASE_PATH/.resources/templates/kustomization.yaml $resources_path/$release/kustomization.yaml
}

# Function : Export the Helm charts from a cluster
# Description:
#   This function exports the Helm charts from a cluster.
#   Gets a list of Helm releases in the cluster using the function "get_helm_releases", and then iterates through each release in the list.
#   For each release, it then calls the function "export_helm_chart_for_release" and passes the release as an argument,
#   which exports the Helm chart for the release to a file.
function export_helm_charts_from_cluster(){
    info "Getting Helm releases from the cluster"
    local helm_releases=$(get_helm_releases)
    for release in $helm_releases
    do
        export_helm_chart_for_release $release
    done
}

# Function : usage
# Description:
#   Prints usage instructions and a list of valid options to the terminal.
function usage() {
    error "Usage: $0 < env | helm | file >"
    warn "\tAvailable options:"
    info "\tenv:    Exports the cluster environment variables to a file named \"env_vars.csv\" in the current directory"
    info "\thelm:   Exports the Helm charts to a directory named \".resources/helm\" in the current directory"
    info "\tyaml:   Exports the YAML files to a directory named \".resources/yaml\" in the current directory"
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
        env-list)print_tabular_output;;
        env)write_to_file;;
        helm)export_helm_charts_from_cluster;;
        yaml)export_yaml_from_cluster;;
        *) usage;;
    esac
}

main $@
