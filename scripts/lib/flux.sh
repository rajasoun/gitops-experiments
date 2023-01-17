#!/usr/bin/env bash

# flux reconcile 
function flux_reconcile(){
    names=("infra-controllers" "infra-configs" "istio-system" "istio-gateway" "dashboard" "apps")
    for name in "${names[@]}"; do
        pretty_print "\n${BLUE}Reconciling $name${NC}\n"
        flux reconcile kustomization "$name" --with-source && pass "Reconciled $name\n" || fail "Failed to reconcile $name\n"
        line_separator
    done
}

