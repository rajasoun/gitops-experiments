#!/usr/bin/env bash

# check if command installed via brew 
function check_brew_packages() {
    GIT_BASE_PATH=$(git rev-parse --show-toplevel)
    PACKAGE_LIST=($(grep -v "^#\|^$" $GIT_BASE_PATH/local-dev/iaac/prerequisites/local/Brewfile | awk '{print $2}' |  tr -d '"'))
    LABEL=$1
    echo -e "\n🧪 Testing $LABEL"
    brew list --version $PACKAGE_LIST[@]
    if [  $?  ];then
        echo -e "✅ $LABEL check passed.\n"
        return 0
    else
        echoStderr "❌ $LABEL check failed.\n"
        FAILED+=("$LABEL")
        return 1
    fi
}

# brew drift check
function check_brew_drift(){
    brew_integrity=$(brew list --version | sha256sum | awk '{print $1}')
    if [ $(cat "${GIT_BASE_PATH}/.github/.setup" | grep -c $brew_integrity) = 1 ];then
        echo -e "${GREEN}\nDrift Check - Passsed${NC}"
        echo -e "   ${GREEN}No Installation(s) found outside of Automation using Homebrew${NC}\n"
        return 0
    else
        echo -e "${RED}\nDrfit Check - Failed${NC}\n"
        echo -e "   ${ORGANGE}Installation(s) found outside of Automation using Homebrew${NC}\n"
        return 1
    fi
}

# audit trail
function audit_trail(){
    brew_integrity=$(brew list --version | sha256sum | awk '{print $1}')
    echo "Installed Packages (via brew) Integrity: $brew_integrity" > ${GIT_BASE_PATH}/.github/.setup
}

# function update audit details 
function do_audit(){
    arg=$1
    if [[ $arg == "--audit" ]]; then
        $HOME/workspace/mac-onboard/assist.sh update-audit-trail
        $HOME/workspace/mac-onboard/assist.sh drift-check
    fi
}

# Function : brew upgrade using $HOME/workspace/mac-onboard/assist.sh brew-upgrade
function brew_upgrade(){
    # exit if not mac using is_mac function
    is_mac || return 1
    pretty_print "${YELLOW}Brew Upgrade${NC}\n"
    # check if file $HOME/workspace/mac-onboard/assist.sh exists
    if [ ! -f $HOME/workspace/mac-onboard/assist.sh ]; then
        fail "${RED}${BOLD}File $HOME/workspace/mac-onboard/assist.sh does not exist${NC}\n"
        warn "${BLUE}Do Setup : https://github.com/rajasoun/mac-onboard/blob/main/README.md ${NC}\n"
        return 1
    fi
    $HOME/workspace/mac-onboard/assist.sh brew-upgrade
    if [ $? -eq 0 ]; then
        pass "${GREEN}${BOLD}Brew Upgrade - Passed${NC}\n"
    else
        fail "${RED}${BOLD}Brew Upgrade - Failed${NC}\n"
    fi
    audit_trail
    # update audit details
    $HOME/workspace/mac-onboard/assist.sh update-audit-trail
    brew list --versions > ./logs/brew_list_versions.log
    brew cleanup
    line_separator
}