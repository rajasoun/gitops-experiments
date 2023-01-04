#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

# port forward
# $1 - namespace
# $2 - service name
# $3 - port - format <local_port>:<remote_port>
function start_port_forward() {
  namespace=$1
  service=$2
  port=$3
  kubectl port-forward --namespace=$namespace svc/$service $port > /dev/null 2>&1 &
  sleep 1
  server_pid=$!
  echo $server_pid
}

# function check_http_code()
# $1 - url
# $2 - expected http code
function check_http_code() {
  url=$1
  pretty_print "${YELLOW}Checking HTTP Code for $url ${NC}\n"
  expected_http_code=$2
  status_code=$(http --headers --check-status --ignore-stdin $url | grep HTTP | cut -d ' ' -f 2)
  echo -e "\n"
  # check http_code is 200
  if [ $status_code == $2 ]; then
    pass "$url Reachable\n"
    http $url
  else
    fail "$url Not Reachable\n"
  fi
}

function wait_till_action_complete(){
  action=$1
  service=$2
  namespace=$3
  pretty_print "${BOLD}${UNDERLINE}Waiting for $action to be ready on $service ${NC}\n"
  case $action in
    "apply")
      kubectl wait --for=condition=available --timeout=30s deployment/$service  -n $namespace
      ;;
    "delete")
      kubectl wait --for=delete --timeout=30s deployment/$service -n $namespace
      ;;
  esac
}

# deploy service
# Parameters:
# $1 - service name
# $2 - manifest path
# $3 - namespace
function manage_deployment() {
  namespace="infrastructure-demo"
  action=$1
  service=$2
  manifest=$3
  
  # deploy service if manifest is not None and file exists
  manifest_full_path="$GIT_BASE_PATH/gitops/validators/$manifest"
  if [ "$manifest" != "None" ] && [ -f "$manifest_full_path" ]; then
    pretty_print "${BOLD}${UNDERLINE}$action $service ${NC}\n"
    kubectl $action -f "$manifest_full_path" -n $namespace
    sleep 10
    wait_till_action_complete $action $service $namespace
  else 
    pretty_print "Skipping deployment for $service_name\n"
  fi
  line_separator
}

# test nginx ingress
function nginx_ingress_test(){
    namespace=$1
    service=$2
    port=$3
    url=$4
    # port forward
    pretty_print "${BOLD}${UNDERLINE}Testing $service for Nginx Ingress ${NC}\n"
    pretty_print "${YELLOW}Port Forwarding${NC}\n"
    server_pid=$(start_port_forward $namespace $service $port)
    local_port=$(echo $port | cut -d ':' -f 1)
    # check http code for nginx ingress
    check_http_code "$url:$local_port" 200
    # kill port forward
    kill $server_pid
    line_separator
}

# test istio ingress
function istio_ingress_test(){
    url=$1
    pretty_print "${BOLD}${UNDERLINE}Testing $service for Istio Ingress ${NC}\n"
    check_http_code "$url" 200
    line_separator
}

function test_service(){
  service_name=$1
  namespace=$2
  service=$3
  port=$4
  test_url=$5
  manifest=$6

  # deploy service if manifest is not None and file exists
  manage_deployment "apply" "$service_name" "$manifest" "$namespace"
  # test nginx ingress test
  nginx_ingress_test "$namespace" "$service" "$port" "$test_url"
  # check istio ingress
  istio_ingress_test "$test_url"
  # undeploy service if manifest is not None and file exists
  manage_deployment "delete" "$service_name" "$manifest" "$namespace"
}

function test(){
  # load yaml to bash array usimh yq
  yaml_file="$GIT_BASE_PATH/gitops/validators/resources/services.yaml"
  services_csv=$(yq eval -o=csv "$yaml_file" | tail -n +2)
  while IFS="," read -r service_name namespace service port test_url manifest
  do
    pretty_print "${BOLD}${UNDERLINE}Testing $service_name ${NC}\n"
    test_service "$service_name" "$namespace" "$service" "$port" "$test_url" "$manifest"
  done < <(echo "$services_csv")
}

trap "exit" INT TERM ERR
trap "kill 0" EXIT
source "${SCRIPT_LIB_DIR}/main.sh" $@
wait 


