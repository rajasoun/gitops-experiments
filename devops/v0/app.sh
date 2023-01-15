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
tier=${3:-frontend}

namespace="apps"
label="app=$app,tier=$tier"
image="$app:latest"
host="$app.local.gd"
service_path="/*"
service_port_mapping="$app:80" 
ingress_name="$app-app-ingress"
env_path="$GIT_BASE_PATH/devops/v0/$app.env"

# Environment variables with defaults to nginx
# check $1 for app name is passed
function create_state_file(){
  echo "app=$app" > $env_path
  echo "namespace=$namespace" >> $env_path
  echo "image=$image" >> $env_path
  echo "host=$host" >> $env_path
  echo "service_path=$service_path" >> $env_path
  echo "service_port_mapping=$service_port_mapping" >> $env_path
  echo "ingress_name=$ingress_name" >> $env_path
}

# function teardown state file if exists
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
  deploy_nginx_ingress_controller
  create_namespace
  create_deployment
  create_service
  create_ingress
}


# teardown
function teardown(){
  delete_deployment
  delete_service
  delete_ingress
  delete_namespace
  teardown_nginx_ingress_controller
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
 
