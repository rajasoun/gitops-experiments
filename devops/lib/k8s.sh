#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

# Function: Print the status of a command
# Parameters:
#   $1 - message: The message to be printed.
#   $2 - exit_code: The exit code of the command.
# Returns:
#   None
# Example:
#   print_command_status "Command completed successfully" 0
function print_command_status(){
  local message=$1
  local exit_code=$2
  if [ $exit_code -eq 0 ]; then
    pass "$message\n"
  else
    fail "$message\n"
  fi
}

# Function: check if a Kubernetes resource exists
# Parameters:
#   $1 - resource type (e.g. deployment, service, ingress)
#   $2 - resource name
#   $3 - namespace
# Returns:
#   0 if the resource exists, 1 if it does not
# Example:
#   check_if_resource_exists "deployment" "my-deployment" "default"
function check_if_resource_exists() {
  local resource_type=$1
  local resource_name=$2
  local namespace=$3
  local exit_code
  pretty_print "${BLUE}Executing : kubectl get $resource_type $resource_name -n $namespace ${NC}\n"
  kubectl get $resource_type $resource_name -n $namespace 
  exit_code="$?"
  if [ $exit_code -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

# Function: Create a patch with labels for a Kubernetes resource
# Parameters:
#   $1 - type: The type of the resource (e.g. deployment, pod, service, ingress).
#   $2 - resource_name: The name of the resource.
#   $3 - labels: A string containing the labels in json format to be added to the resource
# Returns:
#   The exit code of the kubectl patch command.
# Example:
#   create_patch_with_labels "deployment" "my-deployment" "{\"app\":\"my-app\",\"tier\":\"production\"}"
function create_patch_with_labels(){
  local type="$1"
  local resource_name="$2"
  local labels="$3"
  local exit_code
  pretty_print "${BLUE}Executing : kubectl patch $type $resource_name -p $lables ${NC}\n"
  kubectl patch $type $resource_name -p $lables  -n $namespace
  exit_code="$?"
  print_command_status "Status" "$exit_code"
  return "$exit_code"
}

# Function: Get the name of pods of a deployment in a namespace
# Parameters:
#   $1 - deployment_name: The name of the deployment.
#   $2 - namespace: The namespace where the deployment is located.
# Returns:
#   The pod name if successful, otherwise an empty string
# Example:
#   pod_name=$(get_pod_name_of_deployment "my-deployment" "my-namespace")

function get_pod_name_of_deployment() {
  local label=$1
  local namespace=$2
  local exit_code
  pretty_print "${BLUE}Executing : kubectl get pods -l $label -n $namespace -o jsonpath='{.items[*].metadata.name}' | awk '{print $NF}' ${NC}\n"
  kubectl get pods -l $label -n $namespace -o jsonpath='{.items[*].metadata.name}' | awk '{print $NF}'
  exit_code=$?
  if [ $exit_code -eq 0 ]; then
    echo "$pod_name"
  else
    echo ""
  fi
}

# Function : Create a Kubernetes namespace
# Parameters:
#   $1 - namespace: The name of the namespace
# Returns:
#   0 if the namespace was created successfully, 1 otherwise
# Example:
#   create_namespace "my-namespace"
function create_namespace() {
  local namespace=$1
  local exit_code

  local namespace_count=$(kubectl get namespace | grep -c "$namespace")
  # check if namespace already exists supress output
  if [ $namespace_count -gt 0 ]; then
    warn "Namespace $namespace exists. Skipping...\n"
    return 0
  fi

  pretty_print "${BLUE}Executing : kubectl create namespace $namespace ${NC}\n"
  kubectl create namespace "$namespace"
  exit_code="$?"
  print_command_status "Status" $exit_code
  if [ $exit_code -eq 0 ]; then
    create_patch_with_labels "namespace" "$namespace" "$labels" "$namespace"
    return 0
  else
    return 1
  fi
}

# Function: Create a Kubernetes deployment
# Parameters:
#   $1 - resource_type: The type of the resource (e.g. deployment, service, ingress).
#   $2 - resource_name: The name of the resource
#   $3 - namespace: The namespace where the resource should be created.
#   $4 - labels: A string containing the labels in json format to be added to the resource
#   $5 - resource_options: Additional options for the resource creation command
# Returns:
#   0 if the resource was created successfully, 1 otherwise
# Example:
#   create_resource "deployment" "my-deployment" "my-namespace" "{\"app\":\"my-app\",\"tier\":\"production\"}" "--image=nginx:latest"

function create_deployment() {
  local deployment_name=$1
  local namespace=$2
  local labels=$2
  local deployment_options=$4
  local exit_code

  # check if resource already exists in namespace supress output
  if check_if_resource_exists "deployment" "$deployment_name" "$namespace" > /dev/null; then
    warn "Resource $deployment_name of type deployment exists in namespace $namespace.Skipping...\n"
    return 0
  fi

  pretty_print "${BLUE}Executing : kubectl create deployment "$deployment_name" "$deployment_options" -n "$namespace" ${NC}\n"
  kubectl create deployment "$deployment_name" "$deployment_options" -n "$namespace"
  exit_code="$?"
  print_command_status "Status" $exit_code
  if [ $exit_code -eq 0 ]; then
    create_patch_with_labels "deployment" "$resource_name" "$labels" "$namespace"
    return 0
  else
    return 1
  fi
}

# Function: Create a Kubernetes service clusterip
# Parameters:
#   $1 - service_name: The name of the service
#   $2 - namespace: The namespace where the service should be created
#   $3 - labels: A string containing the labels in json format to be added to the service
#   $4 - port: The port of the service
#   $5 - target_port: The target port of the service
# Returns:
#   0 if the service was created successfully, 1 otherwise
# Example:
#   create_service_clusterip "my-service" "my-namespace" "{\"app\":\"my-app\",\"tier\":\"production\"}" "80" "8080"
function create_service_with_clusterip() {
  local service_name=$1
  local namespace=$2
  local labels=$3
  local port_mapping=$4
  local exit_code

  # check if service already exists in namespace supress output
  if check_if_resource_exists "service" "$service_name" "$namespace" > /dev/null; then
    warn "Service $service_name exists in namespace $namespace. Skipping...\n"
    return 0
  fi
  pretty_print "${BLUE}Executing : kubectl create service clusterip $service_name --tcp=$port_mapping -n $namespace ${NC}\n"
  kubectl create service clusterip $service_name --tcp=$port_mapping -n $namespace
  exit_code="$?"
  print_command_status "Status" $exit_code
  if [ $exit_code -eq 0 ]; then
    create_patch_with_labels "service" "$service_name" "$labels" "$namespace"
    return 0
  else
    return 1
  fi
}

# Function: Create a Kubernetes ingress for nginx ingress controller
# Parameters:
#   $1 - ingress_name: The name of the ingress
#   $2 - namespace: The namespace where the ingress should be created.
#   $3 - labels: A string containing the labels in json format to be added to the ingress
# Returns:
#   0 if the ingress was created successfully, 1 otherwise
# Example:
#   
function create_ingress() {
  local ingress_name=$1
  local namespace=$2
  local labels=$3
  local exit_code

  # check if ingress  already exists
  local ingress_count=$(kubectl get ingress -n "$namespace" | grep -c "$ingress_name")
  if [ $ingress_count -gt 0 ]; then
    warn "Ingress $ingress_name exists in namespace $namespace. Skipping...\n"
    return 0
  fi
  pretty_print "${BLUE}Executing : kubectl create ingress "$ingress_name" --class=nginx --rule="$ingress_rules" -n "$namespace" ${NC}\n"
  kubectl create ingress "$ingress_name" --class=nginx --rule="$app.local.gd/*=$app:80" -n "$namespace" 
  exit_code="$?"
  print_command_status "Status" $exit_code
  if [ $exit_code -eq 0 ]; then
    create_patch_with_labels "ingress" "$ingress_name" "$labels" "$namespace"
    return 0
  else
    return 1
  fi
}

# Function: Delete a Kubernetes resource
# Parameters:
#   $1 - resource_type: The type of the resource (e.g. deployment, pod, service, ingress)
#   $2 - resource_name: The name of the resource
#   $3 - namespace: The namespace where the resource is located
# Returns:
#   The exit code of the kubectl delete command.
# Example:
#   delete_resource "deployment" "my-deployment" "default"
function delete_resource() {
  local resource_type=$1
  local resource_name=$2
  local namespace=$3
  local exit_code

  # check if resource exists before deleting and supress output
  if check_if_resource_exists "$resource_type" "$resource_name" "$namespace" > /dev/null; then
    pretty_print "${BLUE}Executing : kubectl delete $resource_type $resource_name -n $namespace ${NC}\n"
    kubectl delete $resource_type $resource_name -n $namespace
    exit_code="$?"
    print_command_status "Status" $exit_code
    return "$exit_code"
  else
    warn "${YELLOW}Resource ${BLUE}$resource_name${NC} of type ${BLUE}$resource_type${NC} in namespace ${BLUE}$namespace${NC} does not exist. Skipping...${NC}"
    return 0
  fi
}

# Function: Apply a Kubernetes manifest from a URL and add labels to the resources defined in it
# Parameters:
#   $1 - url: The URL of the manifest file
#   $2 - labels: A string containing the labels in json format to be added to the resource
# Returns:
#   The exit code of the kubectl apply command.
# Example:
#   apply_manifest_from_url_with_labels "https://example.com/manifest.yaml" "{\"app\":\"my-app\",\"env\":\"production\"}"
function apply_manifest_from_url() {
  local url=$1
  local deployment_name=$2
  local namespace=$3
  local exit_code

  # check if nginx-ingress-controller exists before deleting
  if ! check_if_resource_exists "deployment" "$deployment_name" "$namespace" > /dev/null; then
    pretty_print "${BLUE}Executing command: kubectl delete -f $url ${NC}\n"
    kubectl apply -f $url 
    exit_code=$?
    print_command_status "Status" "$exit_code"
    return "$exit_code"
  else
    warn "Resource $deployment_name of type deployment in namespace $namespace already exist. Skipping...\n"
    return 0
  fi
}


# Function: Delete Kubernetes resources defined in a manifest file from a URL
# Parameters:
#   $1 - url: The URL of the manifest file
# Returns:
#   The exit code of the kubectl delete command.
# Example:
#   delete_manifest_from_url "https://example.com/manifest.yaml"
function delete_manifest_from_url() {
  local url=$1
  local deployment_name=$2
  local namespace=$3
  local exit_code
  
  # check if nginx-ingress-controller exists before deleting
  if check_if_resource_exists "deployment" "$deployment_name" "$namespace" > /dev/null; then
    pretty_print "${BLUE}Executing command: kubectl delete -f $url ${NC}\n"
    kubectl delete -f $url 
    exit_code=$?
    print_command_status "Status" "$exit_code"
    return "$exit_code"
  else
    warn "Resource $deployment_name of type deployment in namespace $namespace does not exist. Skipping...\n"
    return 0
  fi
}
