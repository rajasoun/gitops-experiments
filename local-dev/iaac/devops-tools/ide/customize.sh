#!/usr/bin/env bash 

set -eo pipefail
IFS=$'\n\t'

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

# check if extension is installed
function is_installed(){
    extension=$1
    count=$(code --list-extensions | grep -c $extension)
    if [ $count -gt 0 ]; then
        echo "true"
    else
        echo "false"
    fi
}

# setup vscode extensions
function setup(){
    extensions=$(cat $GIT_BASE_PATH/local-dev/iaac/devops-tools/ide/extensions.txt)
    for extension in $extensions; do
        if [ $(is_installed $extension) == "false" ]; then
            pretty_print "${YELLOW}INFO - Installing $extension${NC}\n"
            code --install-extension $extension
        else
            pretty_print "${YELLOW}INFO - $extension is already installed. Upgrading${NC}\n"
            code --install-extension $extension --force
        fi
    done
}

# teardown vscode extensions
function teardown(){
    extensions=$(cat $GIT_BASE_PATH/local-dev/iaac/devops-tools/ide/extensions.txt)
    for extension in $extensions; do
        if [ $(is_installed $extension) == "true" ]; then
            pretty_print "${YELLOW}INFO - Uninstalling $extension${NC}\n"
            code --uninstall-extension $extension
        fi
    done
}

# test vscode extensions
function test(){
    extensions=$(cat $GIT_BASE_PATH/local-dev/iaac/devops-tools/ide/extensions.txt)
    for extension in $extensions; do
        if [ $(is_installed $extension) == "true" ]; then
            pretty_print "${GREEN}INFO - $extension$ Installed${NC}\n"
        fi
    done
}

# status vscode extensions
function status(){   
    test
}

source "${SCRIPT_LIB_DIR}/main.sh" $@
