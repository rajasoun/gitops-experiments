#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

# print pass or fail based on command exit code
# Parameters
# $1 - message  to print
# $2 - exit code
function print_command_status(){
  local message=$1
  local exit_code=$2
  if [ $exit_code -eq 0 ]; then
    pass "$message\n"
  else
    fail "$message\n"
  fi
}

# Function to check if a Kubernetes resource exists
# Parameters:
# $1 - resource type (e.g. deployment, service, ingress)
# $2 - resource name
# $3 - namespace
function check_if_resource_exists() {
  local resource_type=$1
  local resource_name=$2
  local namespace=$3
  if kubectl get $resource_type $resource_name -n $namespace > /dev/null 2>&1; then
    pretty_print "${BLUE}Resource $resource_name of type $resource_type already exists in namespace $namespace. ${NC}\n"
    return 1
  else
    pretty_print "${BLUE}$resource_name of type $resource_type does not exist in namespace $namespace. ${NC}\n"
    return 0
  fi
}

# create patch with labels
# Parameters
# $1 - type (deployment, pod, service, ingress)
# $2 - resource name
function create_patch_with_labels(){
  local type="$1"
  local resource_name="$2"
  local lables="{\"metadata\": {\"labels\": {\"app\": \"$app\", \"tier\": \"$tier\"}}}"
  # if pod is gnerated by deployment, then use slectors to get pod name
  pretty_print "${BLUE}Creating patch for $resource_name of type $type ${NC}\n"
  pretty_print "Executing: kubectl patch $type $resource_name -p $lables  -n $namespace"
  kubectl patch $type $resource_name -p $lables  -n $namespace
  print_command_status "Patch for $resource_name of type $type\n" "$?"
}

# Function to create a Kubernetes resource
# Parameters:
# $1 - resource type (e.g. deployment, service, ingress)
# $2 - resource name
# $3 - namespace
# $4 - resource specific options 
function create_resource() {
  local resource_type=$1
  local resource_name=$2
  local namespace=$3
  local options=$4

  pretty_print "${BLUE}Creating resource $resource_name of type $resource_type in namespace $namespace with options $options ${NC}\n"
  kubectl create $resource_type $resource_name $options -n $namespace
  print_command_status "Resource $resource_name of type $resource_type created in namespace $namespace" "$?"
}

# setup nginx ingress controller 
function deploy_nginx_ingress_controller(){
  # check if nginx ingress controller is already deployed
    if kubectl get namespace ingress-nginx > /dev/null 2>&1; then
        warn "Nginx Ingress Controller already deployed.Skipping\n"
    else
        pretty_print "${BLUE}Deploying Nginx Ingress Controller${NC}\n"
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/cloud/deploy.yaml
        kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
        print_command_status "Nginx Ingress Controller deployed" "$?"
    fi
}

# teardown nginx ingress controller
function teardown_nginx_ingress_controller(){
    # check if nginx ingress controller is already deployed
    if kubectl get namespace ingress-nginx > /dev/null 2>&1; then
        warn "Deleting Nginx Ingress Controller\n"
        kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/cloud/deploy.yaml
        print_command_status "Nginx Ingress Controller deleted\n" "$?"
    else
        warn "${YELLOW}Nginx Ingress Controller is not deployed. Skipping${NC}\n"
    fi
}

# create namespace
function create_namespace(){
  # check if namespace exists
  if kubectl get namespace $namespace > /dev/null 2>&1; then
    pretty_print "${YELLOW}Namespace $namespace already exists${NC}\n"
  else
    pretty_print "${BLUE}Creating namespace $namespace${NC}\n"
    kubectl create namespace $namespace
    create_patch_with_labels "namespace" "$namespace"
    pass "Namespace $namespace created\n"
  fi
}

# create deployment 
function create_deployment(){
  # check if deployment exists
  if kubectl get deployment $app -n $namespace > /dev/null 2>&1; then
    pretty_print "${YELLOW}Deployment already Exists for app=$app in namespace=$namespace ${NC}\n"
  else
    pretty_print "${BLUE}Creating deployment $app${NC}\n"
    # create deployment with label app=$app
    kubectl create deployment $app --image=$image -n $namespace
    create_patch_with_labels "deployment"
    create_patch_with_labels "pods"
    pass "Deployment $app created\n"
    # wait till deployment is ready
    kubectl wait --for=condition=available --timeout=30s deployment/$app -n $namespace
  fi
}

# create service
function create_service(){
  # check if service exists
  if kubectl get service $app -n $namespace > /dev/null 2>&1; then
    pretty_print "${YELLOW}Service already Exists for app=$app in namespace=$namespace ${NC}\n"
  else
    pretty_print "${BLUE}Creating service $app${NC}\n"
    # create service with label app=$app
    kubectl expose deployment $app --port=80 --target-port=80 --name $app --selector=app=$app -n $namespace
    create_patch_with_labels "service"
    pass "Service $app created\n"
  fi
}

# create ingress with host and path
function create_ingress(){
  # check if ingress controller is running
  if ! kubectl get pod -l app.kubernetes.io/name=ingress-nginx -n ingress-nginx > /dev/null 2>&1; then
    pretty_print "${YELLOW}Ingress controller is not running.Exitting !!!${NC}\n"
    pretty_print "${YELLOW}Please run setup${NC}\n"
    exit 1
  fi
  if kubectl get ingress $ingress_name -n $namespace > /dev/null 2>&1; then
    pretty_print "${YELLOW}Ingress $ingress_name Exist.Exitting !!!${NC}\n"
    exit 1
  fi
  pretty_print "${BLUE}Ingress controller is running${NC}\n"
  # create ingress with host and path
  pretty_print "${BLUE}Creating ingress for $app in namespace $namespace ${NC}\n"
  # create ingress with label app=$app
  echo "kubectl create ingress $ingress_name --class=nginx --rule=\"$host$service_path=$service_port_mapping\" -n $namespace"
  #kubectl create ingress "$ingress_name" --class=nginx --rule=\"$host$service_path=$service_port_mapping\" -n "$namespace"
  kubectl create ingress "$ingress_name" --class=nginx --rule="nginx.local.gd/*=nginx:80" -n "$namespace"
  create_patch_with_labels "ingress"
  pass "Ingress $app created in namespace $namespace \n"
  # wait till ingress is ready
  kubectl wait --for=condition=ready --timeout=30s ingress/$ingress_name -n $namespace
}

# delete deployment
function delete_deployment(){
  # check if deployment exists
  if kubectl get deployment $app -n $namespace > /dev/null 2>&1; then
    pretty_print "${BLUE}Deleting deployment $app${NC}\n"
    kubectl delete deployment $app -n $namespace
    pass "Deployment $app deleted\n"
  else
    warn "=Deployment does not exist for app=$app in namespace=$namespace\n"
  fi
}

# delete service
function delete_service(){
  # check if service exists
  if kubectl get service $app -n $namespace > /dev/null 2>&1; then
    pretty_print "${BLUE}Deleting service $app${NC}\n"
    kubectl delete service $app -n $namespace
    pass "Service $app Deleted\n"
  else
    warn "Service does not exist for app=$app in namespace=$namespace\n"
  fi
}

# delete ingress
function delete_ingress(){
  # check if ingress exists
  if kubectl get ingress $ingress_name -n $namespace > /dev/null 2>&1; then
    pretty_print "${BLUE}Deleting ingress $app${NC}\n"
    kubectl delete ingress $ingress_name -n $namespace
    pass "Ingrees $ingress_name Deleted for app $app\n"
  else
    warn "Ingress does not exist for app=$app in namespace=$namespace\n"
  fi
}

# delete namespace
function delete_namespace(){
  # check if namespace exists
  if kubectl get namespace $namespace > /dev/null 2>&1; then
    pretty_print "${BLUE}Deleting namespace $namespace${NC}\n"
    kubectl delete namespace $namespace
    pass "Namespace $namespace deleted\n"
  else
    warn "Namespace $namespace does not exists\n"
  fi
}

# check if ingress controller is running - if not return 1 else return 0
function check_ingress_controller(){
  if ! kubectl get pod -l app.kubernetes.io/name=ingress-nginx -n ingress-nginx > /dev/null 2>&1; then
     fail "Ingress controller is not running.${NC}\n"
    return 1
  else
    pass "Ingress controller is running"
    return 0
  fi
} 

# check if namespace exists - if not return 1 else return 0
function check_namespace_exists(){
  if ! kubectl get namespace $namespace > /dev/null 2>&1; then
    fail "Namespace $namespace does not exists.${NC}\n"
    return 1
  else
    pass "Namespace $namespace exists"
    return 0
  fi
}

# check if deployment exists - if not return 1 else return 0
function check_deployment_exists(){
  if ! kubectl get deployment $app -n $namespace > /dev/null 2>&1; then
    fail "Deployment $app does not exists in namespace $namespace.${NC}\n"
    return 1
  else
    pass "Deployment $app exists in namespace $namespace" 
    return 0
  fi
}

# check if service exists - if not return 1 else return 0
function check_service_exists(){
  if ! kubectl get service $app -n $namespace > /dev/null 2>&1; then
    fail "Service $app does not exists in namespace $namespace.${NC}\n"
    return 1
  else
    pass "Service $app exists in namespace $namespace"
    return 0
  fi
}

# check if ingress exists - if not return 1 else return 0
function check_ingress_exists(){
  if ! kubectl get ingress $app -n $namespace > /dev/null 2>&1; then
    fail "Ingress $app does not exists in namespace $namespace.${NC}\n"
    return 1
  else
    pass "Ingress $app exists in namespace $namespace"
    return 0
  fi
}

# exit on error
function exit_on_error(){
  local error_code=$1
  if [ $error_code -ne 0 ]; then
    pretty_print "${RED}Error occured. Exiting !!!${NC}\n"
    pretty_print "${YELLOW}Please run setup${NC}\n"
    exit 1
  fi
}

# post checks
function post_checks(){
  local error=0
  check_ingress_controller || error=1
  check_namespace_exists ||  error=1
  check_deployment_exists || error=1
  check_ingress_exists || error=1
  exit_on_error $error
}

# app status 
function print_app_status(){
  pretty_print "${BLUE}Checking status for app=$app in namespace=$namespace${NC}\n"
  # get ingress controller deployment is available
  pretty_print "${YELLOW}Ingress Controller Status${NC}\n"
  kubectl get pod -l app.kubernetes.io/name=ingress-nginx -n ingress-nginx
  # get namespace status
  pretty_print "${YELLOW}Namespace Status${NC}\n"
  kubectl get namespace $namespace
  # get deployment status
  pretty_print "${YELLOW}Deployment Status${NC}\n"
  kubectl get deployment $app -n $namespace
  # get service status
  pretty_print "${YELLOW}Service Status${NC}\n"
  kubectl get service $app -n $namespace
  # get ingress status
  pretty_print "${YELLOW}Ingress Status${NC}\n"
  kubectl get ingress $app -n $namespace
  line_separator
}