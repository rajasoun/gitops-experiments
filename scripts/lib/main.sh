#!/usr/bin/env bash

SCRIPT_LIB_DIR="$(dirname "${BASH_SOURCE[0]}")"

source "${SCRIPT_LIB_DIR}/os.sh"
source "${SCRIPT_LIB_DIR}/k8s.sh"

opt="$1"
choice=$( tr '[:upper:]' '[:lower:]' <<<"$opt" )
case $choice in
    check)time_it check $@;;
    setup)time_it setup $@;;
    teardown)time_it teardown $@;;
    test)time_it test $@;;
    status)status $@;;
    *)
    echo "${RED}Usage: $0 < setup | teardown | test | status >${NC}"
cat <<-EOF
Commands:
---------
check         -> Check
setup         -> Setup  
teardown      -> Teardown 
test          -> Test 
status        -> Status
EOF
    ;;
esac
