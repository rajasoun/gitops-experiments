#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

function check(){
    [ ! -f .env ] && iaac/env/env.sh setup
    $GIT_BASE_PATH/local-dev/iaac/prerequisites/prerequisite.sh check 
    $GIT_BASE_PATH/local-dev/iaac/devops-tools/k9s/customize.sh check
    $GIT_BASE_PATH/local-dev/iaac/env/env.sh check
    $GIT_BASE_PATH/local-dev/iaac/kubernetes/k3d/k3d.sh check
}

function setup(){   
    $GIT_BASE_PATH/local-dev/iaac/prerequisites/prerequisite.sh setup 
    $GIT_BASE_PATH/local-dev/iaac/devops-tools/k9s/customize.sh setup
    $GIT_BASE_PATH/local-dev/iaac/env/env.sh setup
    $GIT_BASE_PATH/local-dev/iaac/kubernetes/k3d/k3d.sh setup
}

function teardown(){
    $GIT_BASE_PATH/local-dev/iaac/kubernetes/k3d/k3d.sh teardown
    $GIT_BASE_PATH/local-dev/iaac/env/env.sh teardown
    $GIT_BASE_PATH/local-dev/iaac/devops-tools/k9s/customize.sh teardown
    #$GIT_BASE_PATH/local-dev/iaac/prerequisites/prerequisite.sh teardown
}

function test(){
    $GIT_BASE_PATH/local-dev/iaac/prerequisites/prerequisite.sh test
    $GIT_BASE_PATH/local-dev/iaac/kubernetes/k3d/k3d.sh test
    $GIT_BASE_PATH/local-dev/iaac/devops-tools/k9s/customize.sh test
}

function status(){    
    $GIT_BASE_PATH/local-dev/iaac/prerequisites/prerequisite.sh status
    $GIT_BASE_PATH/local-dev/iaac/kubernetes/k3d/k3d.sh status
    pretty_print "${GREEN}${UNDERLINE}POD Status By Namespace\n${NC}" 
    pretty_print "${YELLOW}Executing -> kubectl get pods -A --sort-by='.metadata.namespace'\n${NC}" 
    kubectl get pods -A --sort-by='.metadata.namespace'
}

source "${SCRIPT_LIB_DIR}/main.sh" $@