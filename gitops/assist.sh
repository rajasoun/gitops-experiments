#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

#Run bootstrap for a public repository on a personal account
function flux_bootstrap(){
  flux bootstrap github \
    --owner=$GITHUB_USER \
    --repository=$GITHUB_REPO \
    --branch=$GITHUB_BRANCH \
    --path=./gitops/clusters/dev \
    --private=false \
    --personal=true
}

function setup(){
  $GIT_BASE_PATH/local-dev/iaac/env/env.sh setup
  flux_bootstrap
}

function teardown(){
  flux uninstall --namespace=flux-system
  $GIT_BASE_PATH/local-dev/iaac/env/env.sh teardown
}

function test(){
  pretty_print "${BOLD}${UNDERLINE}GitHub Token Tests\n${NC}"
  $GIT_BASE_PATH/local-dev/iaac/env/env.sh test
  line_separator
  pretty_print "${BOLD}${UNDERLINE}Flux Bootstrap Tests\n${NC}"
  $GIT_BASE_PATH/local-dev/iaac/test/validate.sh
  line_separator
}

function status(){    
    pretty_print "${YELLOW}Executing -> kubectl get pods -A --sort-by='.metadata.namespace'\n${NC}" 
    kubectl get pods --namespace=flux-system --sort-by='.metadata.namespace'
}

source "${SCRIPT_LIB_DIR}/main.sh" $@