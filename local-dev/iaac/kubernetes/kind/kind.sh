#!/usr/bin/env bash

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

export $(grep -v "^#\|^$" .env | envsubst | xargs)
export CLUSTER_NAME=${CLUSTER_NAME:-"dev"}

# check k3d ckuster already exists 
function is_kind_cluster_exists(){
    cluster_count=$(kind get clusters | grep -c ${CLUSTER_NAME})
    if [[ $cluster_count -gt 0 ]]; then
        echo "true"
    else 
        echo "false"
    fi
}

function create_cluster(){
    try kind create cluster --name $CLUSTER_NAME  --wait 5m --config="$GIT_BASE_PATH/local-dev/iaac/kubernetes/kind/config/kind.yaml" 
    export KUBECONFIG="$(kind get kubeconfig --name=${CLUSTER_NAME})"
    pretty_print "${GREEN}kind cluster created successfully\n${NC}"
    pretty_print "${YELLOW}Waiting for pods to comeup\n${NC}"
    # Temp Fix
    kind get kubeconfig --name=${CLUSTER_NAME} --internal > /tmp/kind-config
    # List Running Containers
    pretty_print "${GREEN}Running Containers: \n${NC}"
    docker ps --format 'table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Ports}}'
    try source ${SCRIPT_LIB_DIR}/tools.sh
    pretty_print "${GREEN}kind Installation Sucessfull${NC}\n"
}

function setup(){
    if [[ $(is_kind_cluster_exists) == "true" ]]; then
        pretty_print "${YELLOW}kind cluster already exists. Skipping...\n${NC}"
        return 1
    fi
    try create_cluster
}

function teardown(){
    if [[ $(is_kind_cluster_exists) == "false" ]]; then
        pretty_print "${ORANGE}kind cluster does not exists. Skipping...\n${NC}"
        return 1
    fi
    try kind delete cluster --name $CLUSTER_NAME
}

function test(){
    local result=0
    if [[ $(is_kind_cluster_exists) == "false" ]]; then
        pretty_print "${ORANGE}kind cluster does not exists. Skipping...\n${NC}"
        result=1
    else 
        pretty_print "${YELLOW}kind cluster exists. \n${NC}"
        kubectl get --raw='/readyz?verbose' || result=1
        try $GIT_BASE_PATH/local-dev/iaac/test/validate.sh || result=1
    fi
    return $result
}

function status(){
    if [[ $(is_kind_cluster_exists) == "false" ]]; then
        pretty_print "${ORANGE}kind cluster does not exists. Skipping...\n${NC}"
        return 1
    fi
    pretty_print "${GREEN}${UNDERLINE}Status \n${NC}"
    pretty_print "${YELLOW}Executing -> kubectl get nodes -A\n${NC}" 
    kubectl get nodes -A
    line_separator
    pretty_print "${YELLOW}Executing -> kubectl get pods -n kube-system\n${NC}" 
    kubectl wait --for=condition=Ready --timeout=60s pods --all -n kube-system 
    line_separator
}

source "${SCRIPT_LIB_DIR}/main.sh" $@