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
    # List Running Containers
    pretty_print "${GREEN}Running Containers: \n${NC}"
    docker ps --format 'table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Ports}}'
    # pretty_print "${YELLOW}Waiting for pods to comeup\n${NC}"
    # kubectl wait -n kube-system --for=condition=ready pods --all --timeout=120s
    pretty_print "${GREEN}kind Installation Sucessfull${NC}"
}

function check(){
    if [[ $(is_kind_cluster_exists) == "true" ]]; then
        pretty_print "${YELLOW}kind cluster exists. \n${NC}"
        kubectl get --raw='/readyz?verbose'
    fi
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
    if [[ $(is_kind_cluster_exists) == "false" ]]; then
        pretty_print "${ORANGE}kind cluster does not exists. Skipping...\n${NC}"
        return 1
    fi
    try local/test/validate.sh
}

function status(){
    if [[ $(is_kind_cluster_exists) == "false" ]]; then
        pretty_print "${ORANGE}kind cluster does not exists. Skipping...\n${NC}"
        return 1
    fi
    pretty_print "${GREEN}${UNDERLINE}POD Status \n${NC}"
    pretty_print "${YELLOW}Executing -> kubectl get pods -n kube-system\n${NC}" 
    kubectl get pods -n kube-system
}

source "${SCRIPT_LIB_DIR}/main.sh" $@