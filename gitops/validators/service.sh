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

# deploy service
# Parameters:
# $1 - service name
# $2 - manifest path
# $3 - namespace
function deploy_service() {
  service=$1
  manifest=$2
  namespace=$3
  pretty_print "${BOLD}${UNDERLINE}Deploying $service ${NC}\n"
  kubectl apply -f "$manifest" -n $namespace
  sleep 10
  pretty_print "${BOLD}${UNDERLINE}Waiting for $service to be ready${NC}\n"
  kubectl wait --for=condition=available --timeout=30s deployment/$service  -n $namespace
  line_separator
}

# deploy service
# Parameters:
# $1 - service name
# $2 - manifest path
# $3 - namespace
function undeploy_service() {
  service=$1
  manifest=$2
  namespace=$3
  pretty_print "${BOLD}${UNDERLINE}UnDeploying $service ${NC}\n"
  kubectl delete -f "$manifest" -n $namespace
  pretty_print "${BOLD}${UNDERLINE}Waiting for ${service_array[0]} to be delete${NC}\n"
  kubectl wait --for=delete --timeout=30s deployment/$service -n $namespace
  line_separator
}


function deploy_and_test(){
  # array of services with service_name namespace service port urls to check and manifest path
    local services=(
      "httpd ingress-nginx ingress-nginx-controller 8080:80 http://httpd.dev.local.gd:8080 http://httpd.dev.local.gd $GIT_BASE_PATH/gitops/validators/resources/httpd.yaml"
    )
    for service in "${services[@]}"; do
      IFS=' ' read -r -a service_array <<< "$service"
      deploy_service ${service_array[0]} ${service_array[6]} "infrastrcuture-demo"
      pretty_print "${BOLD}${UNDERLINE}Testing ${service_array[0]} using Nginx Ingress Controller & port-forward${NC}\n"
      pretty_print "${YELLOW}Starting Port Forward${NC}\n"
      pid=$(start_port_forward ${service_array[1]} ${service_array[2]} ${service_array[3]})
      pretty_print "${YELLOW}Test ${service_array[1]}${NC}\n"
      check_http_code ${service_array[4]} "200"
      kill $pid
      line_separator
      pretty_print "${BOLD}${UNDERLINE}Testing ${service_array[0]} istio Virtual Service${NC}\n"
      check_http_code ${service_array[5]} "200"
      line_separator
      undeploy_service ${service_array[0]} ${service_array[6]} "infrastrcuture-demo"
    done
}

# function test deployed services
function test_deployed_services(){
  # array of services with service_name namespace service port and urls to check 
  # format: "service_name namespace service port port_forward__url istio_url"
  local deployed_services=(
    "weave-gitops-dashboard dashboard weave-gitops 9001:9001 http://gitops.local.gd:9001 http://gitops.local.gd"
    "podinfo ingress-nginx ingress-nginx-controller 8080:80 http://podinfo.local.gd:8080 http://podinfo.local.gd"
  )
  for deployed_service in "${deployed_services[@]}"; do
    IFS=' ' read -r -a deployed_service_array <<< "$deployed_service"
    pretty_print "${BOLD}${UNDERLINE}Testing ${deployed_service_array[0]} using Nginx Ingress Controller & port-forward${NC}\n"
    pretty_print "${YELLOW}Starting Port Forward${NC}\n"
    pid=$(start_port_forward ${deployed_service_array[1]} ${deployed_service_array[2]} ${deployed_service_array[3]})
    pretty_print "${YELLOW}Test ${deployed_service_array[1]}${NC}\n"
    check_http_code ${deployed_service_array[4]} "200"
    kill $pid
    line_separator
    pretty_print "${BOLD}${UNDERLINE}Testing ${deployed_service_array[0]} istio Virtual Service${NC}\n"
    check_http_code ${deployed_service_array[5]} "200"
    line_separator
  done

}

# test 
function test(){
  deploy_and_test 
  test_deployed_services
}

trap "exit" INT TERM ERR
trap "kill 0" EXIT
source "${SCRIPT_LIB_DIR}/main.sh" $@
wait 


