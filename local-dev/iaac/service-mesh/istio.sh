#!/usr/bin/env bash

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

# install kubernetes gateway api 
function install_gateway_api(){
    kubectl get crd gateways.gateway.networking.k8s.io || \
    { 
        pretty_print "${YELLOW}Istio Gateway CRD not found - Installing${NC}\n"
        kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.5.0" | kubectl apply -f -; 
    }
}

# uninstall kubernetes gateway api 
function uninstall_gateway_api(){
    kubectl get crd gateways.gateway.networking.k8s.io && \
    { 
        pretty_print "${YELLOW}Istio Gateway CRD found - Uninstalling${NC}\n"
        kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.5.0" | kubectl delete -f -; 
    }
}


# setup istio
function setup(){
    install_istioctl
    export PATH=$HOME/.istioctl/bin:$PATH 
    source <(istioctl completion zsh)
    #istioctl x precheck 
    istioctl version
    # istio configuration Profile - https://istio.io/latest/docs/setup/additional-setup/config-profiles/
    # Use the minimal configuration profile
    istioctl install --set profile=default -y
    
    # Add a namespace label to instruct Istio to automatically inject Envoy 
    # sidecar proxies when you deploy your application later
    kubectl label namespace default istio-injection=enabled
     # Ensure that there are no issues with the configuration
    istioctl analyze -A
    install_gateway_api
    pretty_print "${GREEN}istio Installation Sucessfull${NC}\n"
}

# test istio installation
function test(){
    local result=0
    export PATH=$HOME/.istioctl/bin:$PATH 
    source <(istioctl completion zsh)
    pretty_print "${BOLD}${UNDERLINE}istio Tests${NC}\n}"
    pretty_print "${YELLOW}Version Test\n${NC}"
    istioctl version || { fail "istioctl version"; result=1; }
    line_separator
    pretty_print "${YELLOW}Executing -> istioctl analyze -A\n${NC}"
    istioctl analyze -A || { fail "istioctl analyze -A"; result=1; }
    line_separator
    pretty_print "${YELLOW}Executing -> istioctl x precheck\n${NC}"
    istioctl x precheck  || { fail "istioctl x precheck"; result=1; }
    line_separator
    return $result
}

# status 
function status(){
    pretty_print "${BOLD}${UNDERLINE}istio status${NC}\n}"
    pretty_print "${YELLOW}Executing -> kubectl get pods -n istio-system\n${NC}"
    kubectl get pods -n istio-system
    line_separator
    pretty_print "${YELLOW}Executing -> kubectl get svc -n istio-system\n${NC}"
    kubectl get svc -n istio-system
    line_separator  
    pretty_print "${YELLOW}Executing -> kubectl get gateway -n istio-system\n${NC}"
    kubectl get gateway -n istio-system
    line_separator
}

# teardown istio
function teardown(){
    export PATH=$HOME/.istioctl/bin:$PATH 
    source <(istioctl completion zsh)
    istioctl version
    istioctl uninstall -y --purge
    kubectl delete namespace istio-system
    kubectl label namespace default istio-injection-
    uninstall_gateway_api
    #rm -fr $HOME/.istioctl
    echo -e "${GREEN}istio teardown Sucessfull${NC}"
}

source "${SCRIPT_LIB_DIR}/main.sh" $@