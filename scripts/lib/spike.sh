#!/usr/bin/env bash

############## Un Used #################

# install Brewfile by directory name 
# Parameters:
#   $1 - app - e.g. "devops-tools"
function brew_install(){
    local app="$1"
    local directory="$GIT_BASE_PATH/local-dev/iaac/prerequisites/local"
    local brewfile="$directory/$app/Brewfile"

    if [ -f "$brewfile" ]; then
        pretty_print "${BLUE}Installing Brewfile for $app ${NC}\n"
        pretty_print "Brewfile -> $brewfile\n"
        brew bundle --file="$brewfile"
    else
        pretty_print "${RED}Brewfile not found for $app ${NC}\n"
        pretty_print "Brewfile -> $brewfile\n"
    fi
}

# uninstall Brewfile by directory name 
# Parameters:
#   $1 - app - e.g. "devops-tools"

function brew_uninstall(){
    local app="$1"
    GIT_BASE_PATH=$(git rev-parse --show-toplevel)
    local brewfile="$GIT_BASE_PATH/local-dev/iaac/prerequisites/local/$app/Brewfile"
    if [ -f "$brewfile" ]; then
        pretty_print "${BLUE}Uninstalling Brewfile for $app ${NC}\n"
        pretty_print "Brewfile -> $brewfile\n"
        rm -fr /tmp/Brewfile
        cat  $GIT_BASE_PATH/local-dev/iaac/prerequisites/global/Brewfile > /tmp/Brewfile
        echo -e "\n" >> /tmp/Brewfile
        cat $GIT_BASE_PATH/local-dev/iaac/prerequisites/local/Brewfile >> /tmp/Brewfile
        brew bundle --file /tmp/Brewfile cleanup --force
        rm -fr /tmp/Brewfile
    else
        pretty_print "${RED}Brewfile not found for $app ${NC}\n"
        pretty_print "Brewfile -> $brewfile\n"
    fi
}

# open url in default browser 
# Parameters:
#   $1 - url - e.g. "http://localhost:8080"
function open_url(){
    local url="$1"
    pretty_print "${YELLOW}Opening URL in default browser${NC}\n"
    #open "$url"
    # check if python3 is installed
    if command -v python3 &> /dev/null; then
        python3 -m webbrowser -t "$url"
    else
       open "$url" 
    fi
}

# build terminal url
# Parameters:
#   $1 - link_name - e.g. "Google"
#   $2 - url - e.g. "http://google.com"
function build_terminal_link(){
    link_name="$(trim $1)"
    url="$(trim $2)"
    echo $link_name
    formatted_text="\e]8;;$url\e\\$link_name\e]8;;\e\\n"
    echo "$formatted_text"
}

# strip all leading and trailing spaces from a string
# Parameters:
#   $1 - string - e.g. "  hello world  "
function trim(){
    string="$1"
    echo "$string" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

# print doc references
# Parameters:
#   $1 - csv_file - e.g. "scripts/docs/references.csv"
function print_doc_reference(){
    csv_file="$1"
    # parse csv file ignoring first line and empty lines
    csv_file_content=$(cat "$csv_file" | tail -n +2 | sed '/^$/d')
    # check if csv file is empty
    if [ -z "$csv_file_content" ]; then
        echo -e "${RED}No Doc references found in $csv_file${NC}.Exiting !!!"
        return 1
    fi
    # print each line in csv_file_content
    while IFS=, read -r sno topic url; do
        # trim leading and trailing spaces
        sno=$(trim "$sno")
        topic=$(trim "$topic")
        url=$(trim "$url")

        formatted_text="\e]8;;$url\e\\$topic\e]8;;\e\\n"
        printf "$sno. ${BLUE}$formatted_text${NC}"
    done <<< "$csv_file_content"
}

# Function: patch nginx-ingress-controller type NodePort to LoadBalancer
function patch_nginx_ingress_controller(){
    pretty_print "${YELLOW}Patching nginx-ingress-controller type from NodePort to LoadBalancer${NC}\n"
    # Start by getting the name of the nginx-ingress-controller service
    kubectl get services -n ingress-nginx
    # Patch the service to change the type from NodePort to LoadBalance
    kubectl patch service nginx-ingress-controller -n ingress-nginx -p '{"spec":{"type":"LoadBalancer"}}'
    # Verify that the service type has been updated - Command should return LoadBalancer
    kubectl get service nginx-ingress-controller -n ingress-nginx -o jsonpath='{.spec.type}'
    kubectl get service nginx-ingress-controller -n ingress-nginx
}
