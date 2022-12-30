#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

function get_kubernetes_type(){
    load_env
    if [ "$KUBERNETES_TYPE" == "k3d" ]; then
        echo "k3d"
    elif [ "$KUBERNETES_TYPE" == "kind" ]; then
        echo "kind"
    else
        echo "k3d"
    fi
}

function check(){
    [ ! -f .env ] && $GIT_BASE_PATH/local-dev/iaac/env/env.sh setup
    $GIT_BASE_PATH/local-dev/iaac/prerequisites/prerequisite.sh check 
    $GIT_BASE_PATH/local-dev/iaac/devops-tools/k9s/customize.sh check
    $GIT_BASE_PATH/local-dev/iaac/env/env.sh check
    kubernetes_type=$(get_kubernetes_type)
    $GIT_BASE_PATH/local-dev/iaac/kubernetes/$kubernetes_type/$kubernetes_type.sh check
}

function setup(){   
    $GIT_BASE_PATH/local-dev/iaac/prerequisites/prerequisite.sh setup 
    $GIT_BASE_PATH/local-dev/iaac/devops-tools/k9s/customize.sh setup
    $GIT_BASE_PATH/local-dev/iaac/env/env.sh setup
    kubernetes_type=$(get_kubernetes_type)
    $GIT_BASE_PATH/local-dev/iaac/kubernetes/$kubernetes_type/$kubernetes_type.sh setup
}

function teardown(){
    kubernetes_type=$(get_kubernetes_type)
    $GIT_BASE_PATH/local-dev/iaac/kubernetes/$kubernetes_type/$kubernetes_type.sh teardown
    $GIT_BASE_PATH/local-dev/iaac/devops-tools/k9s/customize.sh teardown
    #$GIT_BASE_PATH/local-dev/iaac/env/env.sh teardown
    #$GIT_BASE_PATH/local-dev/iaac/prerequisites/prerequisite.sh teardown
}

function test(){
    pretty_print "${BOLD}${UNDERLINE}Pre Requisites Tests\n${NC}"
    $GIT_BASE_PATH/local-dev/iaac/prerequisites/prerequisite.sh test
    line_separator
    pretty_print "${BOLD}${UNDERLINE}k9s customizaions Tests\n${NC}"
    $GIT_BASE_PATH/local-dev/iaac/devops-tools/k9s/customize.sh test
    line_separator
    kubernetes_type=$(get_kubernetes_type)
    pretty_print "${BOLD}${UNDERLINE}Kubernetes Cluster [$kubernetes_type] Tests\n${NC}"
    $GIT_BASE_PATH/local-dev/iaac/kubernetes/$kubernetes_type/$kubernetes_type.sh test
    line_separator
}

function status(){    
    $GIT_BASE_PATH/local-dev/iaac/prerequisites/prerequisite.sh status
    kubernetes_type=$(get_kubernetes_type)
    $GIT_BASE_PATH/local-dev/iaac/kubernetes/$kubernetes_type/$kubernetes_type.sh status
    pretty_print "${GREEN}${UNDERLINE}POD Status By Namespace\n${NC}" 
    pretty_print "${YELLOW}Executing -> kubectl get pods -A --sort-by='.metadata.namespace'\n${NC}" 
    kubectl get pods -A --sort-by='.metadata.namespace'
}

source "${SCRIPT_LIB_DIR}/main.sh" $@