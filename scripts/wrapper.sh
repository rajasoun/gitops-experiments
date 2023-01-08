#!/usr/bin/env bash

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

source "${SCRIPT_LIB_DIR}/os.sh"

# Execute Function
function execute_function(){
    shift 
    function_name=$1
    #echo $function_name
    shift
    if [ -n "$function_name" ]; then
        source "${SCRIPT_LIB_DIR}/tools.sh" > /dev/null 2>&1
        if [ "$(type -t $function_name)" == "function" ]; then
             args=$@
             pretty_print "${UNDERLINE}Executing function: $function_name $args${NC}\n"
             $function_name $args
        else
            echo "Function $function_name not found"
            exit 1
        fi
    fi
}

# List Functions
function list_functions(){
    exclude_functions="try\|die\|yell\|pass\|fail\|echoStderr\|install_tool\|main\|time_it\|pretty_print\|line_separator\|print_usage\|execute_function\|list_functions"
    pretty_print "${BOLD}${UNDERLINE}${YELLOW}Available functions${NC}\n"
    declare -F  | awk '{print $3}' | grep -v "$exclude_functions" | sort 
    line_separator
}

# Watch - Invoke scripts/iterm2/watch.sh
function watch(){
    "$GIT_BASE_PATH/scripts/iterm2/watch.sh"
}

# Docs Pointer 
function docs(){
    # clear the terminal buffer
    clear 
    # get github remote url 
    pretty_print "${BOLD}${UNDERLINE}${YELLOW}Documentation Pointers${NC}\n"
    echo -e "\n"   
    mdcat "$GIT_BASE_PATH/docs/v0/console.md"
    # in line edit .vscode/settings.json to replace line .md": "default  .md": "vscode.markdown.preview.editor
    sed -i '' 's/.md": "default/.md": "vscode.markdown.preview.editor/g' "$GIT_BASE_PATH/.vscode/settings.json"
    code "$GIT_BASE_PATH/docs/v0/concepts.md"
    sleep 1
    # in line edit .vscode/settings.json to replace line .md": "vscode.markdown.preview.editor  .md": "default
    sed -i '' 's/.md": "vscode.markdown.preview.editor/.md": "default/g' "$GIT_BASE_PATH/.vscode/settings.json"
}

# Print Usage
function print_usage(){
    echo "${RED}Usage: $0 < run | list | watch >${NC}"
cat <<-EOF
    Commands:
    ---------
    run           -> Run Function  
    list          -> List Functions in os.sh 
    watch         -> Invoke scripts/iterm2/watch.sh
    docs          -> Print Docs Pointers
EOF
}


opt="$1"
choice=$( tr '[:upper:]' '[:lower:]' <<<"$opt" )
case $choice in
    run)execute_function $@;;
    list)list_functions $@;;
    watch)watch $@;;
    docs)docs $@;;
    *) # Invalid option
    print_usage;;
esac








