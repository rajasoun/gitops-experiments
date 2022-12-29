#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"


# test
function test(){
    kubectl apply -f $GIT_BASE_PATH/gitops/validators/resources/http-echo.yaml
    # wait for pod to be ready
    kubectl wait --for=condition=ready pod -l app=http-echo --timeout=60s
    http 'http://dev.local.gd/echo'
    if [ $? -eq 0 ]; then
        pass "Nginx Ingress test passed\n"
    else
        fail "Nginx Ingress test failed\n"
    fi
    kubectl delete -f $GIT_BASE_PATH/gitops/validators/resources/http-echo.yaml
}

source "${SCRIPT_LIB_DIR}/main.sh" $@