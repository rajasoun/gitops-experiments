#!/usr/bin/env bash

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"


# setup
function setup(){
    is_mac
    check_for_docker_desktop
    brew bundle --file $GIT_BASE_PATH/local-dev/iaac/prerequisites/local/Brewfile
    source "${SCRIPT_LIB_DIR}/tools.sh"
    echo -e "${GREEN}Pre Requisites setup DONE!!!${NC}"
}

# test
function test(){
    result=$(brew bundle --file $GIT_BASE_PATH/local-dev/iaac/prerequisites/local/Brewfile check)
    # grep result for dependencies are satisfied
    if [[ $result == *"dependencies are satisfied."* ]]; then
        pass "Pre Requisites for devops-tools"
    else
        fail "Pre Requisites for devops-tools"
    fi
}

# status
function status(){
    pretty_print "${GREEN}${UNDERLINE}Pre Requisites Tools \n${NC}"
    brew bundle --file $GIT_BASE_PATH/local-dev/iaac/prerequisites/local/Brewfile list
}

# teardown
function teardown(){
    brew bundle --file $GIT_BASE_PATH/local-dev/iaac/prerequisites/global/Brewfile --cleanup
    brew cleanup
    rm -fr bin/*
    echo -e "${GREEN}Pre Requisites Teardown Sucessfull!!!${NC}"
}

source "${SCRIPT_LIB_DIR}/main.sh" $@