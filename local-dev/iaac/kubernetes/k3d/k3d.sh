#!/usr/bin/env bash

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

export $(grep -v "^#\|^$" .env | envsubst | xargs)
export CLUSTER_NAME=${CLUSTER_NAME:-"dev"}

# check k3d ckuster already exists 
function is_k3d_cluster_exists(){
    cluster_count=$(k3d cluster list | grep -c ${CLUSTER_NAME})
    if [[ $cluster_count -gt 0 ]]; then
        echo "true"
    else 
        echo "false"
    fi
}

function create_cluster(){
    try k3d cluster create --registry-config <(cat $GIT_BASE_PATH/local-dev/iaac/kubernetes/k3d/config/registries.yaml | envsubst) --config  <(cat $GIT_BASE_PATH/local-dev/iaac/kubernetes/k3d/config/k3d-config.yaml | envsubst)
    export KUBECONFIG=$(k3d kubeconfig write $CLUSTER_NAME)
    echo "KUBECONFIG=${KUBECONFIG}"
    pretty_print "${GREEN}k3d cluster created successfully\n${NC}"
    pretty_print "${YELLOW}Waiting for pods to comeup\n${NC}"
    sleep 30
    # wait untill all pods are in Ready State
    kubectl wait --for=condition=Ready pods --all -n kube-system
    # List Running Containers
    pretty_print "${GREEN}Running Containers: \n${NC}"
    docker ps --format 'table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Ports}}'
    try source ${SCRIPT_LIB_DIR}/tools.sh
    echo -e "${GREEN}k3d Installation Sucessfull${NC}"
}

function check(){
    echo -e "\n"
    if [[ $(is_k3d_cluster_exists) == "true" ]]; then
        pass "$k3d cluster"
        echo -e "\n"
        kubectl get --raw='/readyz?verbose'
        if [[ $? -eq 0 ]]; then
            pass "k3d cluster is healthy"
        else
            fail "k3d cluster is unhealthy"
        fi
    else 
        fail "$k3d cluster"
    fi
    echo -e "\n"
}

function setup(){
    # try k3d cluster create $CLUSTER_NAME --k3s-arg="--disable=traefik@server:*"
    # cat config/k3d-config.yaml | envsubst > /tmp/k3d-config.yaml
    if [[ $(is_k3d_cluster_exists) == "true" ]]; then
        pretty_print "${YELLOW}k3d cluster already exists. Skipping...\n${NC}"
        return 1
    fi
    create_cluster

}

function teardown(){
    if [[ $(is_k3d_cluster_exists) == "false" ]]; then
        pretty_print "${ORANGE}k3d cluster does not exists. Skipping...\n${NC}"
        return 1
    fi
    k3d cluster delete $CLUSTER_NAME
}

function test(){
    if [[ $(is_k3d_cluster_exists) == "false" ]]; then
        pretty_print "${ORANGE}k3d cluster does not exists. Skipping...\n${NC}"
        return 1
    fi
    $GIT_BASE_PATH/local-dev/iaac/test/validate.sh
}

function status(){
    if [[ $(is_k3d_cluster_exists) == "false" ]]; then
        pretty_print "${ORANGE}k3d cluster does not exists. Skipping...\n${NC}"
        return 1
    fi
    pretty_print "${GREEN}${UNDERLINE}POD Status \n${NC}"
    pretty_print "${YELLOW}Executing -> kubectl get pods -n kube-system\n${NC}" 
    kubectl get pods -n kube-system
}

source "${SCRIPT_LIB_DIR}/main.sh" $@