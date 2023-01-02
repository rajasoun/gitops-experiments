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
  pretty_print "${BOLD}${UNDERLINE}Testing Podinfo${NC}\n"
  # pretty_print "${YELLOW}Starting Port Forward${NC}\n"
  # pid=$(start_port_forward)
  pretty_print "${YELLOW}Test podinfo${NC}\n"
  load_env
  http http://podinfo.local.gd
  echo -e "\n"
  if [ $? -eq 0 ]; then
    pass "podinfo test passed\n"
  else
    fail "podinfo test failed\n"
  fi
  # kill $pid
  line_separator
}


trap "exit" INT TERM ERR
trap "kill 0" EXIT
source "${SCRIPT_LIB_DIR}/main.sh" $@
wait 


