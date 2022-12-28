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

# function to check prerequisites
function pre_check(){
  load_env
  # check if local-dev directory exists
  [ ! -d $GIT_BASE_PATH/local-dev ] && fail "local-dev directory not found" && return 1 || pass "local-dev directory found\n"
  # check if kubernetes cluster is running
  [ $(k3d cluster list  | grep -c $CLUSTER_NAME ) -eq 0 ] && fail "k3d cluster [$CLUSTER_NAME] not running" && return 1 || pass "k3d cluster [$CLUSTER_NAME] running\n"
  # check is devops tools are installed 
  [ $(brew bundle --file $GIT_BASE_PATH/local-dev/iaac/prerequisites/local/Brewfile check | grep -c "The Brewfile's dependencies are satisfied.") -eq 0 ] && fail "devops tools not installed" && return 1 || pass "devops tools installed\n"
  # check flux check
  [ $(flux check --pre) ] && fail "flux prerequisites not met" && return 1 || pass " flux prerequisites met\n"
  # check github token
  [ $(gh auth status --hostname $GITHUB_BASE_URL) ] && fail "GITHUB_TOKEN not set" && return 1 || pass "GIT_TOKEN valid\n"
  # check github user
  [ $(gh api "https://api.github.com/user" | jq .login | tr -d '"') != $GITHUB_USER ] && fail "GITHUB_USER mismatch" && return 1 || pass "GITHUB_USER=$GITHUB_USER valid\n"
  # check github repo
  [ $(gh repo view --json name -q ".name") != $GITHUB_REPO ] && fail "GITHUB_REPO mismatch" && return 1 || pass "GITHUB_REPO=$GITHUB_REPO valid\n"
  # check github branch
  [ $(git rev-parse --abbrev-ref HEAD) != "$GITHUB_BRANCH" ]  && fail "GITHUB_BRANCH mismatch" && return 1 || pass "GITHUB_BRANCH=$GITHUB_BRANCH valid\n"
  # check flux system kustomization file exists 
  [ ! -f $GIT_BASE_PATH/gitops/clusters/dev/flux-system/kustomization.yaml ] && fail "flux-system kustomization file not found" && return 1 || pass "flux-system kustomization file found\n"
  # check kustomize, kubeconfirm and yaml validation
  $GIT_BASE_PATH/local-dev/iaac/test/validate.sh
  [ "$?" -eq 1 ] && fail "kustomize, kubeconfirm and yq  validation failed\n" && return 1 || pass "kustomize, kubeconfirm and yq validation passed\n"
  return 0
}

# function to check post deployment
function post_check(){
  # check flux-system kustomization is deployed
  [ $(flux get kustomizations --all-namespaces | grep -c "flux-system") -eq 0 ] && fail "flux-system kustomization not deployed" && return 1 || pass "flux-system kustomization deployed\n"
  # check kubernetes cluster is running
  [ ! $(kubectl get --raw '/readyz?verbose' | grep -c "ok") -eq 24 ] && fail "kubernetes cluster is unhealthy" && return 1 || pass "kubernetes cluster is healthy\n"
  # check istio-system kustomization is deployed
  [ $(flux get kustomizations --all-namespaces | grep -c "istio-system") -eq 0 ] && fail "istio-system kustomization not deployed" && return 1 || pass "istio-system kustomization deployed\n"
  return 0
}

function setup(){
  if [ ! -d $GIT_BASE_PATH/.env ]; then
    $GIT_BASE_PATH/local-dev/iaac/env/env.sh setup
  fi
  load_env
  flux_bootstrap
}

function teardown(){
  flux uninstall --namespace=istio-system
  flux uninstall --namespace=flux-system
  $GIT_BASE_PATH/local-dev/iaac/env/env.sh teardown
}

function test(){
  pretty_print "${BOLD}${UNDERLINE}GitHub Token Tests\n${NC}"
  $GIT_BASE_PATH/local-dev/iaac/env/env.sh test
  line_separator
  pretty_print "${BOLD}${UNDERLINE}Pre Check Tests\n${NC}"
  pre_check
  line_separator
  pretty_print "${BOLD}${UNDERLINE}Flux Bootstrap Tests\n${NC}"
  $GIT_BASE_PATH/local-dev/iaac/test/validate.sh
  line_separator
  pretty_print "${BOLD}${UNDERLINE}Post Check Tests\n${NC}"
  post_check
  line_separator
}

function status(){    
    pretty_print "${YELLOW}Executing -> kubectl get pods -A --sort-by='.metadata.namespace'\n${NC}" 
    kubectl get pods -A --sort-by='.metadata.namespace'
}

source "${SCRIPT_LIB_DIR}/main.sh" $@