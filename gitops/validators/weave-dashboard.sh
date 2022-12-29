#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

function start_port_forward() {
  kubectl port-forward --namespace=flux-system svc/weave-gitops 9001:9001 > /dev/null 2>&1 &
  sleep 1
  server_pid=$!
  echo $server_pid
}

function test(){
  pretty_print "${BOLD}${UNDERLINE}Testing Weave Dashboard${NC}\n"
  pretty_print "${YELLOW}Starting Port Forward${NC}\n"
  pid=$(start_port_forward)
  pretty_print "${YELLOW}Test Weave Dashboard${NC}\n"
  curl -s 'http://dev.local.gd:9001/oauth2/userinfo' -H 'Cookie: id_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTY3MjI5NjkwNSwibmJmIjoxNjcyMjkzMzA1LCJpYXQiOjE2NzIyOTMzMDV9.7otq97andmpFMIZutScLzT48libHLYcZ7MG08EjGQyQ' 
  echo -e "\n"
  if [ $? -eq 0 ]; then
    pass "Weave Dashboard test passed\n"
  else
    fail "Weave Dashboard test failed\n"
  fi
  kill $pid
  line_separator
}


trap "exit" INT TERM ERR
trap "kill 0" EXIT
source "${SCRIPT_LIB_DIR}/main.sh" $@
wait 


