#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

# Function : Wait till pods are ready
# Description : Check if pods are ready based on the label selector and namespace provided with a timeout of 120 seconds
# Parameters :
#   $1 - Namespace
#   $2 - Label Selector 
# Returns :
#   None
# Example :
#   wait_till_pods_are_ready "ingress-nginx" "app.kubernetes.io/component=controller"
function wait_till_pods_ready(){
  local namespace=$1
  local label_selector=$2
  local timeout=120s
  kubectl wait --namespace "$namespace" --for=condition=ready pod --selector="$label_selector" --timeout=$timeout
}


# Function : setup 
# Description : Setup the environment
function setup(){
  pretty_print "${BOLD}${UNDERLINE}Setup${NC}\n"
  pretty_print "${BLUE}Deploying ingress-nginx-controller${NC}\n"
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.5.1/deploy/static/provider/cloud/deploy.yaml
  wait_till_pods_ready "ingress-nginx" "app.kubernetes.io/component=controller"
  line_separator
  pretty_print "${BLUE}Deploying nginx app${NC}\n"
  kubectl apply -f $GIT_BASE_PATH/devops/v1/all-in-one/nginx.yaml 
  wait_till_pods_ready "apps" "app=nginx"
  line_separator
}

# Function : teardown
# Description : Teardown the environment
function teardown(){
  pretty_print "${BOLD}${UNDERLINE}Teardown${NC}\n"
  pretty_print "${BLUE}Undeploying nginx app${NC}\n"
  kubectl delete -f $GIT_BASE_PATH/devops/v1/all-in-one/nginx.yaml 
  line_separator
  pretty_print "${BLUE}Undeploying ingress-nginx-controller${NC}\n"
  kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.5.1/deploy/static/provider/cloud/deploy.yaml
  line_separator
}

# Function : test
# Description : Test the environment
function test(){
  http --check-status --ignore-stdin --timeout 5 --verify=no http://nginx.local.gd
}

# Function : status
# Description : Status of the environment
function status(){
  # check if ingress-nginx-controller is running 
  pretty_print "${BOLD}${UNDERLINE}Status${NC}\n"
  pretty_print "${BLUE}ingress-nginx-controller${NC}\n"
  kubectl get pods --field-selector=status.phase=Running -n ingress-nginx
  line_separator
  pretty_print "${BLUE}nginx app${NC}\n"
  kubectl get pods -n apps
  line_separator
  # pretty_print "${BLUE}Check Internet Access within Cluster${NC}\n"
  # kubectl run busybox --image=busybox:latest  --restart=Never --rm -it -- ping 8.8.8.8 -c 2
  # endpoint_ip=$(kubectl get endpoints nginx -n apps -o jsonpath='{.subsets[*].addresses[*].ip}')
  # kubectl run httpie --image=alpine/httpie:latest --restart=Never --rm -it -- http $endpoint_ip:80
  # line_separator
}


source "${SCRIPT_LIB_DIR}/main.sh" $@