#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

# Environment variables with defaults to nginx
app=${1:-nginx}
namespace="apps"
image="$app:latest"
host="$app.local.gd"
service_path="/*"
service_port_mapping="$app:80" 
ingress_name="$app-app-ingress"

# deploy nginx ingress controller with labels
function deploy_nginx_ingress(){
  pretty_print "${BLUE}Deploying Nginx Ingress Controller${NC}\n"
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/cloud/deploy.yaml 
  kubectl wait --for=condition=ready --timeout=30s pod -l app.kubernetes.io/name=ingress-nginx -n ingress-nginx
}


# create namespace
function create_namespace_if_not_exists(){
  # check if namespace exists
  if ! kubectl get namespace $namespace > /dev/null 2>&1; then
    kubectl create namespace $namespace
  fi
}

# create deployment 
function create_deployment(){
   # check if deployment exists
  if kubectl get deployment $app -n $namespace > /dev/null 2>&1; then
    pretty_print "${YELLOW}Deployment already Exists for app=$app in namespace=$namespace ${NC}\n"
    pretty_print "${BLUE}Deleting deployment $app${NC}\n"
    kubectl delete deployment $app -n $namespace
  fi
  pretty_print "${BLUE}Creating deployment $app${NC}\n"
  # create deployment with label app=$app
  kubectl create deployment $app --image=$image --labels=app=$app --port=80 -n $namespace
  
  # wait till deployment is complete 
  kubectl wait --for=condition=available --timeout=30s deployment/$app -n $namespace
  # wait till pod is ready
  kubectl wait --for=condition=ready --timeout=30s pod -l app=$app -n $namespace
}

# create service
function create_service(){
  # check if service exists
  if kubectl get service $app -n $namespace > /dev/null 2>&1; then
    pretty_print "${YELLOW}Service already Exists for app=$app in namespace=$namespace ${NC}\n"
    pretty_print "${BLUE}Deleting service $app${NC}\n"
    kubectl delete service $app -n $namespace
  fi
  pretty_print "${BLUE}Creating service $app${NC}\n"
  # create service with label app=$app
  kubectl expose deployment $app --port=80 --target-port=80 --name=$app --labels=app=$app -n $namespace
  # wait till service is ready
  kubectl wait --for=condition=ready --timeout=30s service/$app -n $namespace
}

# create ingress with host and path
function create_ingress(){
  # check if ingress controller is running
  if ! kubectl get pod -l app.kubernetes.io/name=ingress-nginx -n ingress-nginx > /dev/null 2>&1; then
    pretty_print "${RED}Ingress controller is not running.Exitting !!!${NC}\n"
    pretty_print "${RED}Please run setup${NC}\n"
    exit 1
  fi
  pretty_print "${BLUE}Creating Ingress for app=$app in namespace=$namespace ${NC}\n"
  # check if ingress exists
  if kubectl get ingress $app -n $namespace > /dev/null 2>&1; then
    pretty_print "${YELLOW}Ingress already Exists for app=$app in namespace=$namespace ${NC}\n"
    pretty_print "${BLUE}Deleting ingress $app${NC}\n"
    kubectl delete ingress $app -n $namespace
  fi
  pretty_print "${BLUE}Creating ingress $app${NC}\n"
  # create ingress with label app=$app
  kubectl create ingress $ingress_name --class=nginx --rule="$host$path=$service_port_mapping" --labels=app=$app -n $namespace
  # wait till ingress is ready
  kubectl wait --for=condition=ready --timeout=30s ingress/$ingress_name -n $namespace
}

# setup
function setup(){
  deploy_nginx_ingress
  create_namespace_if_not_exists
  create_deployment
  create_service
  create_ingress
}

# delete deployment if exists
function delete_deployment_if_exists(){
  if kubectl get deployment $app -n $namespace > /dev/null 2>&1; then
    pretty_print "${BLUE}Deleting deployment $app${NC}\n"
    kubectl delete deployment $app -n $namespace
  else 
    pretty_print "${YELLOW}Deployment $app does not exists in namespace $namespace ${NC}\n"
  fi
}

# delete service if exists
function delete_service_if_exists(){
  if kubectl get service $app -n $namespace > /dev/null 2>&1; then
    pretty_print "${BLUE}Deleting service $app${NC}\n"
    kubectl delete service $app -n $namespace
  else 
    pretty_print "${YELLOW}Service $app does not exists in namespace $namespace ${NC}\n"
  fi
}

# delete ingress if exists
function delete_ingress_if_exists(){
  if kubectl get ingress $app -n $namespace > /dev/null 2>&1; then
    pretty_print "${BLUE}Deleting ingress $app${NC}\n"
    kubectl delete ingress $app -n $namespace
  else 
    pretty_print "${YELLOW}Ingress $app does not exists in namespace $namespace ${NC}\n"
  fi
}

# delete namespace if exists
function delete_namespace_if_exists(){
  if kubectl get namespace $namespace > /dev/null 2>&1; then
    pretty_print "${BLUE}Deleting namespace $namespace${NC}\n"
    kubectl delete namespace $namespace
  else 
    pretty_print "${YELLOW}Namespace $namespace does not exists ${NC}\n"
  fi
}

# delete nginx ingress controller
function delete_nginx_ingress(){
  # check if ingress controller is running
  if ! kubectl get pod -l app.kubernetes.io/name=ingress-nginx -n ingress-nginx > /dev/null 2>&1; then
    pretty_print "${YELLOW}Ingress controller is not running.Exitting !!!${NC}\n"
    pretty_print "${YELLOW}Please run setup${NC}\n"
    exit 1
  fi
  pretty_print "${BLUE}Deleting Nginx Ingress Controller${NC}\n"
  kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/cloud/deploy.yaml
}

# teardown
function teardown(){
  delete_deployment_if_exists
  delete_service_if_exists
  delete_ingress_if_exists
  delete_namespace_if_exists
  delete_nginx_ingress
}

# post checks
function post_checks(){
  local error=0
   # check if ingress controller is running
  if ! kubectl get pod -l app.kubernetes.io/name=ingress-nginx -n ingress-nginx > /dev/null 2>&1; then
    fail "Ingress controller is not running. Exitting !!!${NC}\n"
    error=1
  else
    pass "Ingress controller is running"
  fi
  # check if namespace exists
  if ! kubectl get namespace $namespace > /dev/null 2>&1; then
    fail "Namespace $namespace does not exists. Exitting !!!${NC}\n"
    error=1
  else
    pass "Namespace $namespace exists"
  fi
  # check if deployment exists
  if ! kubectl get deployment $app -n $namespace > /dev/null 2>&1; then
    fail "Deployment $app does not exists in namespace $namespace. Exitting !!!${NC}\n"
    error=1
  else
    pass "Deployment $app does nexists in namespace $namespace. ${NC}\n"
  fi
  # check if service exists
  if ! kubectl get service $app -n $namespace > /dev/null 2>&1; then
    fail "Service $app does not exists in namespace $namespace. Exitting !!!${NC}\n"
    error=1
  else
    pass "Service $app does not exists in namespace $namespace"
  fi 
  # check if ingress exists
  if ! kubectl get ingress $app -n $namespace > /dev/null 2>&1; then
    fail "Ingress $app does not exists in namespace $namespace. Exitting !!!${NC}\n"
    error=1
  else
    pass "Ingress $app exists in namespace $namespace."
  fi 
  if [ $error -eq 1 ]; then
    pretty_print "${YELLOW}Please run setup${NC}\n"
    exit 1
  fi
}

# test
function test(){
  post_checks
  pretty_print "${YELLOW}Testing app : $app${NC}\n"
  http http://$host
}

function status(){    
  post_checks
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

trap "exit" INT TERM ERR
trap "kill 0" EXIT
source "${SCRIPT_LIB_DIR}/main.sh" $@
wait 
 
