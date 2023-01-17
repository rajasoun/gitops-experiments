#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
MAIN_SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"
DEVOPS_SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

# Parameters
# $2 - app name
# $3 - tier (frontend, backend, service, etc)
app=${2:-nginx}
namespace="apps"
label="app=$app,tier=$tier"
image="$app:latest"
host="$app.local.gd"
env_path="$GIT_BASE_PATH/devops/v0/$app.env"

nginx_ingress_manifest="https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.5.1/deploy/static/provider/cloud/deploy.yaml"

# Function: Create State File cwith environment variables (app, namespace, image, host, service_path, service_port_mapping, ingress_name)
#
# Description:
# The create_state_file function creates a file with the given name in the env_path directory and writes various environment variables to it. It writes the values of the app, namespace, image, host, service_path, service_port_mapping and ingress_name environment variables to the file, each on its own line.
#
# Input:
#   - env_path : The file path for the state file
#   - app : The name of the app
#   - namespace : The namespace where the app is deployed
#   - image : The name of the image
#   - host : The host of the app
#   - service_path : The path of the service
#   - service_port_mapping : The port mapping of the service
#   - ingress_name : The name of the ingress
#
# Returns:
#   0 if the file is created successfully ands  1 if an error occurs
#
# Example:
#   namespace="apps"
#   label="app=$app,tier=$tier"
#   image="$app:latest"
#   host="$app.local.gd"
#   service_path="/*"
#   service_port_mapping="$app:80" 
#   ingress_name="$app"
#   env_path="$GIT_BASE_PATH/devops/v0/$app.env"
#   create_state_file 
function create_state_file(){
  if [ -f $env_path ]; then
    warn "State : $env_path exists.Overwritting\n"
  fi
  echo "app=$app" > $env_path
  echo "namespace=$namespace" >> $env_path
  echo "image=$image" >> $env_path
  echo "host=$host" >> $env_path
  if [ $? -ne 0 ]; then
    echo "An error occurred while creating $env_path" >&2
    return 1
  fi
  return 0
}

# Function: Deletes the state file located at the path specified by the env_path variable if it exists.
# Parameters:
#   $1 - The file path for the state file#
# Returns:
#   None
# Example:
#   env_path="$GIT_BASE_PATH/devops/v0/$app.env"
#   teardown_state_file 

function teardown_state_file(){
  if [ -f $env_path ]; then
    pretty_print "${BLUE}Deleting state file $env_path${NC}\n"
    rm -fr $env_path
    pass "State file deleted\n"
  else 
    warn "State file $env_path does not exist"
  fi
}

# Function: Deploy Nginx Ingress Controller
# Parameters:
#  None
# Returns:
#   None
# Example:
#   deploy_nginx_ingress_controller
function deploy_nginx_ingress_controller(){
  apply_manifest_from_url "$nginx_ingress_manifest" "ingress-nginx-controller" "ingress-nginx"
  # wait for the deployment to be ready
  kubectl wait --namespace ingress-nginx --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=120s
}

# setup
function setup(){
  local lables="{\"metadata\": {\"labels\": {\"app\": \"$app\", \"tier\": \"frontend\"}}}"

  create_state_file 
  deploy_nginx_ingress_controller
  
  create_namespace "$namespace" 
  create_deployment "$app" "$namespace"  "$labels" "--image=$app:latest"
  create_service_with_clusterip "$app" "$namespace"  "$labels" "80:80"
  create_ingress "$app" "$namespace" "$labels" 
}


# teardown
function teardown(){
  # check if state file exists
  if [ ! -f $env_path ]; then
    warn "State file $env_path does not exist.\n"
  else 
    teardown_state_file
  fi
  delete_manifest_from_url "$nginx_ingress_manifest" "ingress-nginx-controller" "ingress-nginx"
  # get namespace count - supress output
  local namespace_count=$(kubectl get namespace | grep -c $namespace )
  # if namespace count is 1, delete namespace
  if [ $namespace_count -eq 1 ]; then
    delete_resource "ingress" "$app" "$namespace" 
    delete_resource "service" "$app" "$namespace" 
    delete_resource "deployment" "$app" "$namespace" 
    delete_resource "namespace"  "$namespace" "$namespace" 
  fi
}

# test
function test(){
  pretty_print "${YELLOW}Testing app : $app${NC}\n"
  http http://$host
}

# status
function status(){    
  pretty_print "${BLUE}Namespace : $namespace${NC}\n"
  kubectl get namespace $namespace
  line_separator
  pretty_print "${BLUE}Deployment : $app${NC}\n"
  kubectl get deployment $app -n $namespace
  line_separator
  pretty_print "${BLUE}Service : $app${NC}\n"
  kubectl get service $app -n $namespace
  line_separator
  pretty_print "${BLUE}Pods : $app${NC}\n"
  kubectl get pods -n $namespace -l app=$app
  line_separator
  pretty_print "${BLUE}Ingress : $app${NC}\n"
  kubectl get ingress $app -n $namespace
  line_separator
}

trap "exit" INT TERM ERR
trap "kill 0" EXIT
source "${DEVOPS_SCRIPT_LIB_DIR}/k8s.sh"
source "${MAIN_SCRIPT_LIB_DIR}/main.sh" $@
wait 
 
