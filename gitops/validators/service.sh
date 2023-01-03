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

# test 
function test(){
  # array of services with namespace service port and urls to check 
  # format: "namespace service port port_forward__url istio_url"
  services=(
    "dashboard weave-gitops 9001:9001 http://gitops.local.gd:9001 http://gitops.local.gd"
    "ingress-nginx ingress-nginx-controller 8080:80 http://podinfo.local.gd:8080 http://podinfo.local.gd"
  )
  for service in "${services[@]}"; do
    IFS=' ' read -r -a service_array <<< "$service"
    pretty_print "${BOLD}${UNDERLINE}Testing ${service_array[1]} using Nginx Ingress Controller & port-forward${NC}\n"
    pretty_print "${YELLOW}Starting Port Forward${NC}\n"
    pid=$(start_port_forward ${service_array[0]} ${service_array[1]} ${service_array[2]})
    pretty_print "${YELLOW}Test ${service_array[1]}${NC}\n"
    check_http_code ${service_array[3]} "200"
    kill $pid
    line_separator
    pretty_print "${BOLD}${UNDERLINE}Testing ${service_array[1]} istio Virtual Service${NC}\n"
    check_http_code ${service_array[4]} "200"
    line_separator
  done
}

trap "exit" INT TERM ERR
trap "kill 0" EXIT
source "${SCRIPT_LIB_DIR}/main.sh" $@
wait 


