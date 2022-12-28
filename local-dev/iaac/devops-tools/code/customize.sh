#!/usr/bin/env bash 

set -eo pipefail
IFS=$'\n\t'

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

MAC_K9S_HOME="$HOME/Library/Application Support/k9s"

function check(){
    echo -e "\n"
    # check if plugin.xml exists in k9s home
    if [ -f "$MAC_K9S_HOME/plugin.yml" ]; then
        pass "INFO - k9s plugin is installed"
    else
        fail "INFO - k9s plugin is not installed"
    fi
    # check if logoless is enabled in k9s config
    if [ -f "$MAC_K9S_HOME/config.yml" ]; then
        if yq e '.k9s.logoless' $MAC_K9S_HOME/config.yml | grep -q true; then
            pass "INFO - k9s Logo is enabled"
        else
            fail "INFO - k9s Logo is disabled"
        fi
    fi
}

function setup(){
    # copy plugin.xml to k9s home if not exists
    if [ ! -f "$MAC_K9S_HOME/plugin.yml" ]; then
        cp iaac/devops-tools/k9s/plugin.yml $MAC_K9S_HOME
        echo -e "INFO - k9s plugin copied to $MAC_K9S_HOME"
    fi
    if [ -f "$MAC_K9S_HOME/config.yml" ]; then
        yq -i e '.k9s.logoless |= true' $MAC_K9S_HOME/config.yml
        echo -e "INFO - k9s Logo disabled in $MAC_K9S_HOME/config.yml"
    fi
}

function teardown(){
    if [  -f "$MAC_K9S_HOME/plugin.yml" ]; then
        rm -fr $MAC_K9S_HOME/plugin.yml
        echo -e "INFO - k9s plugin removed from $MAC_K9S_HOME"
    fi
    if [ -f "$MAC_K9S_HOME/config.yml" ]; then
        yq -i e '.k9s.logoless |= false' $MAC_K9S_HOME/config.yml
        echo -e "INFO - k9s Logo enabled in $MAC_K9S_HOME/config.yml"
    fi
}

function test(){
    find  iaac/devops-tools/k9s -type f -name '*.yml' -print0 | while IFS= read -r -d $'\0' file;
    do
        echo "INFO - Validating $file"
        yq e 'true' "$file" > /dev/null
    done
}

function status(){   
    # check if plugin.xml exists in k9s home
    if [ -f "$MAC_K9S_HOME/plugin.yml" ]; then
        echo "INFO - k9s plugin is installed"
    else
        echo "INFO - k9s plugin is not installed"
    fi
    # check if logoless is enabled in k9s config
    if [ -f "$MAC_K9S_HOME/config.yml" ]; then
        if yq e '.k9s.logoless' $MAC_K9S_HOME/config.yml | grep -q true; then
            echo "INFO - k9s Logo is enabled"
        else
            echo "INFO - k9s Logo is disabled"
        fi
    fi
}

source "${SCRIPT_LIB_DIR}/main.sh" $@
