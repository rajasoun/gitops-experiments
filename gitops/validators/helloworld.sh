#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

function start_port_forward() {
  kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80 > /dev/null 2>&1 &
  sleep 1
  server_pid=$!
  echo $server_pid
}

function test(){
  kubectl apply -f "$GIT_BASE_PATH/gitops/validators/resources/helloworld.yaml"
  kubectl wait --for=condition=available --timeout=30s deployment/helloworld
  pretty_print "${BOLD}${UNDERLINE}Testing Helloworld via Nginx Ingress${NC}\n"
  pretty_print "${YELLOW}Starting Port Forward${NC}\n"
  pid=$(start_port_forward)
  pretty_print "${YELLOW}Test Helloworld Nginx Ingress${NC}\n"
  http 'http://httpd.dev.local.gd:8080'
  echo -e "\n"
  if [ $? -eq 0 ]; then
    pass "Helloworld Ninx Ingress test passed\n"
  else
    fail "Helloworld Ninx Ingress test ailed\n"
  fi
  kill $pid
  kubectl delete -f "$GIT_BASE_PATH/gitops/validators/resources/helloworld.yaml"
  line_separator
}


trap "exit" INT TERM ERR
trap "kill 0" EXIT
source "${SCRIPT_LIB_DIR}/main.sh" $@
wait 


