#!/usr/bin/env bash

SCRIPT_LIB_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_LIB_DIR}/load.sh"

opt="$1"
choice=$( tr '[:upper:]' '[:lower:]' <<<"$opt" )
case $choice in
    setup)time_it setup $@;;
    test)time_it test $@;;
    status)status $@;;
    teardown)time_it teardown $@;;
    *)
    echo "${RED}Usage: $0 < setup | teardown | test | status >${NC}"
cat <<-EOF
Commands:
---------
setup         -> Setup  
teardown      -> Teardown 
test          -> Test 
status        -> Status
EOF
    ;;
esac
