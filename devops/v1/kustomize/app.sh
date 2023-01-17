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
  pretty_print "${BLUE}Deploying ingress-nginx-controller and Nginx App${NC}\n"
  kustomize build devops/v1/kustomize | kubectl apply -f-
  wait_till_pods_ready "ingress-nginx" "app.kubernetes.io/component=controller"
  wait_till_pods_ready "apps" "app=nginx"
  line_separator
}

# Function : teardown
# Description : Teardown the environment
function teardown(){
  pretty_print "${BOLD}${UNDERLINE}Teardown${NC}\n"
  pretty_print "${BLUE}UnDeploying ingress-nginx-controller and Ngnix App${NC}\n"
  kustomize build devops/v1/kustomize | kubectl delete -f-
  wait_till_pods_ready "ingress-nginx" "app.kubernetes.io/component=controller"
  wait_till_pods_ready "apps" "app=nginx"  
  line_separator
}

# validate the kustomize overlays
function validate_kustomize_overlays() {
  # mirror kustomize-controller build options
  kustomize_flags=("--load-restrictor=LoadRestrictionsNone")
  kustomize_config="kustomization.yaml"
  pretty_print "\t${YELLOW}INFO - Validating kustomize overlays\n${NC}"
  find "$GIT_BASE_PATH/devops/v1/kustomize/" -type f -name $kustomize_config -print0 | while IFS= read -r -d $'\0' file;
    do
      pretty_print "\t${BLUE}INFO - Validating kustomization ${file/%$kustomize_config}\n${NC}"
      kustomize build "${file/%$kustomize_config}" "${kustomize_flags[@]}" | kubeconform "${kubeconform_config[@]}"
      if [[ ${PIPESTATUS[0]} != 0 ]]; then
        exit 1
      fi
  done
  line_separator
}

# Function : test
# Description : Test the environment
function test(){
  validate_kustomize_overlays
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