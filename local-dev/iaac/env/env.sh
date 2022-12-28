#!/usr/bin/env bash

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

GITHUB_BASE_URL="github.com"
ENV_FILE=".env"

# setup
function setup(){
    gh auth login --hostname $GITHUB_BASE_URL --git-protocol https --web
    export GITHUB_USER=$(gh api "https://api.$GITHUB_BASE_URL/user" | jq .login | tr -d '"')
    export GITHUB_REPO=$(gh repo view --json name -q ".name")
    export GITHUB_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    export GITHUB_TOKEN=$(gh auth token)
    cat .env.sample | envsubst > $ENV_FILE
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
    export $(grep -v "^#\|^$" $ENV_FILE| envsubst | xargs)
    echo -e "\n"
    gh auth login --hostname "$GITHUB_BASE_URL"  --with-token <(echo "$GITHUB_TOKEN")
    status
}

source "${SCRIPT_LIB_DIR}/main.sh" $@