#!/usr/bin/env bash

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

GITHUB_BASE_URL="github.com"
ENV_FILE="$GIT_BASE_PATH/.env"

# setup
function setup(){
    gh auth login --hostname $GITHUB_BASE_URL --git-protocol https --web
    export GITHUB_USER=$(gh api "https://api.$GITHUB_BASE_URL/user" | jq .login | tr -d '"')
    export GITHUB_REPO=$(gh repo view --json name -q ".name")
    export GITHUB_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    export GITHUB_TOKEN=$(gh auth token)
    # if KUBERNETES_TYPE is not set, default to k3d
    export KUBERNETES_TYPE=${KUBERNETES_TYPE:-k3d}
    cat "$ENV_FILE.sample"| envsubst > "$ENV_FILE"
}

# teardown
function teardown(){
    rm -fr $ENV_FILE
}

function status(){
    gh auth status --hostname "$GITHUB_BASE_URL" 
    if [ $? -eq 0 ]; then
        pass "Github Auth"
    else
        fail "Github Auth"
    fi
}

function test(){
    local result=0
    export $(grep -v "^#\|^$" $ENV_FILE| envsubst | xargs)
    echo -e "\n"
    gh auth login --hostname "$GITHUB_BASE_URL"  --with-token <(echo "$GITHUB_TOKEN") || result=1
    status || result=1
    return $result
}

source "${SCRIPT_LIB_DIR}/main.sh" $@