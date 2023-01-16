#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
MAIN_SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"
DEVOPS_SCRIPT_LIB_DIR="$GIT_BASE_PATH/devops/lib"

# Parameters
# $2 - app name
# $3 - tier (frontend, backend, service, etc)
app=${2:-nginx}
namespace="apps"
label="app=$app,tier=$tier"
image="$app:latest"
host="$app.local.gd"
service_path="/*"
service_port_mapping="$app:80" 
ingress_name="$app"
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
    echo "$env_path already exists, state will be overwritten"
  fi
  echo "app=$app" > $env_path
  echo "namespace=$namespace" >> $env_path
  echo "image=$image" >> $env_path
  echo "host=$host" >> $env_path
  echo "service_path=$service_path" >> $env_path
  echo "service_port_mapping=$service_port_mapping" >> $env_path
  echo "ingress_name=$ingress_name" >> $env_path
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

# setup
function setup(){
  create_state_file 
  apply_manifest_from_url "$nginx_ingress_manifest" 
  
  local lables="{\"metadata\": {\"labels\": {\"app\": \"$app\", \"tier\": \"$frontend\"}}}"
  create_resource "namespace"  "$namespace" "$namespace"  "$labels"  
  create_resource "deployment" "$app" "$namespace"  "$labels" "--image=$app:latest"
  create_resource "service" "$app" "$namespace"  "$labels" 
  create_ingress  "ingress" "$app" "$namespace"  "$labels" 
}


# teardown
function teardown(){
  delete_manifest_from_url "$nginx_ingress_manifest" 
  # delete_service
  # delete_ingress
  # delete_namespace
  # teardown_nginx_ingress_controller
  teardown_state_file
}

# test
function test(){
  post_checks
  pretty_print "${YELLOW}Testing app : $app${NC}\n"
  http http://$host
}

# status
function status(){    
  #source $GIT_BASE_PATH/devops/v0/$app.env
  post_checks
  print_app_status $app $namespace
}

trap "exit" INT TERM ERR
trap "kill 0" EXIT
source "${DEVOPS_SCRIPT_LIB_DIR}/k8s.sh"
source "${MAIN_SCRIPT_LIB_DIR}/main.sh" $@
wait 
 
