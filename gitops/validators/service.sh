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

function test_service(){
  local service_name=$1
  local url=$2
  pretty_print "${BOLD}${UNDERLINE}Testing $service_name for Istio Ingress ${NC}\n"
  check_http_code "$url" && pass "Service $service_name Check Passed" || fail "Service $service_name Check Failed"
  line_separator
}

function test(){
  pretty_print "${BOLD}${UNDERLINE}Testing Services with Istio Ingress${NC}\n"
  pretty_print "${YELLOW}List Istio Virtual Services  ${NC}\n"
  kubectl get virtualservices.networking.istio.io -A 
  line_separator
  test_service "podinfo" "http://podinfo.local.gd"
  test_service "weave-dashboard" "http://gitops.local.gd"
}

source "${SCRIPT_LIB_DIR}/main.sh" $@



