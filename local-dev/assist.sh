#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/iaac/lib"

function check(){
    [ ! -f .env ] && iaac/env/env.sh setup
    iaac/prerequisites/prerequisite.sh check 
    iaac/devops-tools/k9s/customize.sh check
    iaac/env/env.sh check
    iaac/kubernetes/k3d/k3d.sh check
}

function setup(){   
    iaac/prerequisites/prerequisite.sh setup 
    iaac/devops-tools/k9s/customize.sh setup
    iaac/env/env.sh setup
    iaac/kubernetes/k3d/k3d.sh setup
}

function teardown(){
    iaac/kubernetes/k3d/k3d.sh teardown
    iaac/env/env.sh teardown
    iaac/devops-tools/k9s/customize.sh teardown
    #iaac/prerequisites/prerequisite.sh teardown
}

function test(){
    iaac/prerequisites/prerequisite.sh test
    iaac/kubernetes/k3d/k3d.sh test
    iaac/devops-tools/k9s/customize.sh test
}

function status(){    
    iaac/prerequisites/prerequisite.sh status
    iaac/kubernetes/k3d/k3d.sh status
    pretty_print "${GREEN}${UNDERLINE}POD Status By Namespace\n${NC}" 
    pretty_print "${YELLOW}Executing -> kubectl get pods -A --sort-by='.metadata.namespace'\n${NC}" 
    kubectl get pods -A --sort-by='.metadata.namespace'
}

source "${SCRIPT_LIB_DIR}/main.sh" $@