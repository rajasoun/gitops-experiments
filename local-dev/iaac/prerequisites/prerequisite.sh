#!/usr/bin/env bash

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"


# setup
function setup(){
    is_mac
    check_docker_desktop
    brew bundle --file $GIT_BASE_PATH/local-dev/iaac/prerequisites/local/Brewfile
    shift 1 & do_audit $@
    source "${SCRIPT_LIB_DIR}/tools.sh"
    echo -e "${GREEN}Pre Requisites setup DONE!!!${NC}"
}

# test
function test(){
    pre_check
}

# pre-check 
function pre_check(){
    local result=0
    check_disk_space || result=1
    check_processor || result=1
    check_disk_space || result=1
    check_docker_desktop || result=1
    check_devops_tools || result=1
    check_gh_crendentials || result=1
    # check_aws_credentials || result=1
    return $result
}

# list installed devops tools
function list_installed_devops_tools(){
    local tools=($(brew bundle --file $GIT_BASE_PATH/local-dev/iaac/prerequisites/local/Brewfile list))
    pretty_print "\t${BLUE}Installed Tools \n${NC}"
    # exho tools array
    for tool in "${tools[@]}"; do
        echo -e "\t\t${GREEN}${tool}${NC}"
    done
}

# status
function status(){
    pre_check
    list_installed_devops_tools
    line_separator
}

# teardown
function teardown(){
    pretty_print "${YELLOW}Prerequisites Teardown\n${NC}"
    brew bundle --file $GIT_BASE_PATH/local-dev/iaac/prerequisites/global/Brewfile --cleanup
    brew cleanup
    rm -fr bin/*
    shift 1 & do_audit $@
    echo -e "${GREEN}Pre Requisites Teardown Sucessfull!!!${NC}"
}

source "${SCRIPT_LIB_DIR}/main.sh" $@