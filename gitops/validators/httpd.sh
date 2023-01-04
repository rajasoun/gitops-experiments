#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

# setup
function setup(){
  kustomize build gitops/validators/httpd | kubectl apply -f-
}

# teardown
function teardown(){
  kustomize build gitops/validators/httpd | kubectl delete -f-
}

# test
function nginx_ingress_test(){
  pretty_print "${YELLOW}Starting Port Forward${NC}\n"
  kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80 > /dev/null 2>&1 &
  server_pid=$!
  sleep 3
  status_code=$(http --headers --check-status --ignore-stdin 'http://httpd.local.gd:8080' | grep HTTP | cut -d ' ' -f 2)
  echo -e "\n"
  # check http_code is 200
  if [ $status_code == "200" ]; then
    pass "httpd Nginx Ingress test passed\n"
    http --ignore-stdin 'http://httpd.local.gd:8080'
  else
    fail "httpd Nginx Ingress test failed\n"
  fi
  kill  $server_pid
}

# test
function istio_test(){
  status_code=$(http --headers --check-status --ignore-stdin 'http://httpd.local.gd' | grep HTTP | cut -d ' ' -f 2)
  echo -e "\n"
  # check http_code is 200
  if [ $status_code == "200" ]; then
    pass "httpd Istio test passed\n"
    http --ignore-stdin 'http://httpd.local.gd'
  else
    fail "httpd Istio test failed\n"
  fi
}

# test
function test(){
  pretty_print "${YELLOW}http Test Nginx Ingress${NC}\n"
  nginx_ingress_test
  line_separator
  pretty_print "${YELLOW}http Istio Virtual Service${NC}\n"
  istio_test
  line_separator
}

function status(){    
  pretty_print "${YELLOW}httpd status${NC}\n"
  kubectl wait --for=condition=available --timeout=30s deployment/httpd -n infrastrcuture-demo
  kubectl wait --for=condition=ready --timeout=30s pod -l app=httpd -n infrastrcuture-demo
  line_separator
  pretty_print "${YELLOW}httpd Service Details${NC}\n"
  kubectl get svc httpd -n infrastrcuture-demo 
  line_separator
  pretty_print "${YELLOW}Nginx Ingress${NC}\n"
  kubectl get ingress -n infrastrcuture-demo
  line_separator
  pretty_print "${YELLOW}istio Virtual Service${NC}\n"
  kubectl get virtualservices.networking.istio.io -n infrastrcuture-demo 
  line_separator
}

trap "exit" INT TERM ERR
trap "kill 0" EXIT
source "${SCRIPT_LIB_DIR}/main.sh" $@
wait 
 
