#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

# function check_http_code()
# $1 - url
# $2 - expected http code
function check_http_code() {
  local url=$1
  pretty_print "${YELLOW}Checking HTTP Code for $url ${NC}\n"
  status_code=$(http --headers --check-status --ignore-stdin $url | grep HTTP | cut -d ' ' -f 2)
  echo -e "\n"
  if [ "$status_code" == "200" ]; then
    http --headers --check-status --ignore-stdin $url 
    return 0
  else
    return 1
  fi
}

function wait_till_action_complete(){
  local ction=$1
  local service=$2
  local namespace=$3
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
  local namespace="infrastrcuture-demo"
  local action=$1
  local service=$2
  local manifest=$3

  # deploy service if manifest is not None and file exists
  manifest_full_path="$GIT_BASE_PATH/gitops/validators/$manifest"
  if [ "$manifest" != "None" ] && [ -f "$manifest_full_path" ]; then
    pretty_print "${BOLD}${UNDERLINE}$action $service ${NC}\n"
    kubectl $action -f "$manifest_full_path" 
    sleep 10
    wait_till_action_complete $action $service $namespace
  else 
    pretty_print "Skipping deployment for $service_name\n"
  fi
  line_separator
}

# test nginx ingress
function nginx_ingress_test(){
    local namespace=$1
    local service=$2
    local port=$3
    local url=$4
    # port forward
    pretty_print "${BOLD}${UNDERLINE}Testing $service for Nginx Ingress ${NC}\n"

    pretty_print "${YELLOW}Port Forwarding -> kubectl port-forward --namespace=$namespace svc/$service $port  ${NC}\n"
    kubectl port-forward --namespace=$namespace svc/$service $port > /dev/null 2>&1 &
    sleep 3
    server_pid=$!
    local_port=$(echo $port | cut -d ':' -f 1)
    # check http code for nginx ingress
    check_http_code "$url:$local_port" && pass "Service Check Passed" || fail "Service Check Failed"
    # kill port forward
    kill $server_pid
    line_separator
}

function deploy_test_service(){
  local service_name=$1
  local namespace=$2
  local service=$3
  local port=$4
  local test_url=$5
  local manifest=$6

  # deploy service if manifest is not None and file exists
  manage_deployment "apply" "$service_name" "$manifest" "$namespace"
  # test nginx ingress test
  nginx_ingress_test "$namespace" "$service" "$port" "$test_url"
  # check istio ingress
  pretty_print "${BOLD}${UNDERLINE}Testing $service for Istio Ingress ${NC}\n"
  local_port=$(echo $port | cut -d ':' -f 1)
  check_http_code "$test_url:$local_port" && pass "Service $service Check Passed" || fail "Service $service Check Failed"
  line_separator
  pretty_print "${BOLD}${UNDERLINE}Testing $service for Istio Ingress ${NC}\n"
  check_http_code "$test_url" && pass "Service $service Check Passed" || fail "Service $service Check Failed"
  line_separator
  # undeploy service if manifest is not None and file exists
  manage_deployment "delete" "$service_name" "$manifest" "$namespace"
  line_separator
}

function test_service(){
  local service_name=$1
  local url=$2
  pretty_print "${BOLD}${UNDERLINE}Testing $service for Istio Ingress ${NC}\n"
  check_http_code "$url" && pass "Service $service Check Passed" || fail "Service $service Check Failed"
  line_separator
}

function test(){
  # load yaml to bash array usimh yq
  yaml_file="$GIT_BASE_PATH/gitops/validators/resources/services.yaml"
  services_csv=$(yq eval -o=csv "$yaml_file" | tail -n +2)
  while IFS="," read -r service_name namespace service test_url
  do
    pretty_print "${BOLD}${UNDERLINE}Testing $service_name ${NC}\n"
    test_service "$service_name" "$test_url" 
  done < <(echo "$services_csv")
  deploy_test_service "httpd" "ingress-ngnix" "ingress-nginx-controller" "8080:80" "http://httpd.dev.local.gd" "resources/httpd.yaml"
}

trap "exit" INT TERM ERR
trap "kill 0" EXIT
source "${SCRIPT_LIB_DIR}/main.sh" $@
wait 


