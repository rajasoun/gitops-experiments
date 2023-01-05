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
    local result=0
    pretty_print "${YELLOW}Prerequisites Test\n${NC}"
    MERGED_FILE_CONTENT="$(cat $GIT_BASE_PATH/local-dev/iaac/prerequisites/global/Brewfile)\n$(cat $GIT_BASE_PATH/local-dev/iaac/prerequisites/local/Brewfile)"
    check_result=$(brew bundle --file <(echo $MERGED_FILE_CONTENT) check)
    # grep result for dependencies are satisfied
    if [[ $check_result == *"dependencies are satisfied."* ]]; then
        pass "Pre Requisites for devops-tools"
    else
        fail "Pre Requisites for devops-tools"
        result=1
    fi
    return $result
}

# status
function status(){
    pretty_print "${YELLOW}Prerequisites Status\n${NC}"
    MERGED_FILE_CONTENT="$(cat $GIT_BASE_PATH/local-dev/iaac/prerequisites/global/Brewfile)\n$(cat $GIT_BASE_PATH/local-dev/iaac/prerequisites/local/Brewfile)"
    brew bundle --file <(echo $MERGED_FILE_CONTENT) check && pass "Pre Requisites for devops-tools\n" || fail "Pre Requisites for devops-tools\n"
    pretty_print "${GREEN}Tool List \n${NC}"
    brew bundle --file $GIT_BASE_PATH/local-dev/iaac/prerequisites/local/Brewfile list
    line_separator
}

# teardown
function teardown(){
    pretty_print "${YELLOW}Prerequisites Teardown\n${NC}"
    brew bundle --file $GIT_BASE_PATH/local-dev/iaac/prerequisites/global/Brewfile --cleanup
    brew cleanup
    rm -fr bin/*
    echo -e "${GREEN}Pre Requisites Teardown Sucessfull!!!${NC}"
}

source "${SCRIPT_LIB_DIR}/main.sh" $@