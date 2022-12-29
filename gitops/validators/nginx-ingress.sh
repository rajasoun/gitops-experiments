#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"


# test
function test(){
    kubectl apply -f "$GIT_BASE_PATH/gitops/validators/resources/helloworld.yaml"
    kubectl wait --for=condition=available --timeout=30s deployment/nginx-ingress-demo
    http 'http://dev.local.gd/helloworld'
    if [ $? -eq 0 ]; then
        pass "/helloworld Ingress test passed\n"
    else
        fail "/helloworld Ingress test failed\n"
    fi
    kubectl delete -f "$GIT_BASE_PATH/gitops/validators/resources/helloworld.yaml"
}

source "${SCRIPT_LIB_DIR}/main.sh" $@