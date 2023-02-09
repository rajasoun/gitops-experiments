#!/usr/bin/env bash

# Function : Retrieve a list of all Kubernetes resources in the cluster.
# Description:
#  The kubectl api-resources command is used to get the list of all resources types available in the cluster and 
#  the kubectl get command is used to get the resources. 
#   --namespaced=false option is used to get the resources that are not namespaced 
#   --verbs=list is used to get the list of resources. 
#   -o=name option is used to format the output as "<resource_type>/<resource_name>" for easy readability. 
function get_cluster_resources() {
    # kubectl get -o=name pvc,configmap,serviceaccount,secret,ingress,service,deployment,statefulset,hpa,job,cronjob
    # resource_types=(pvc configmap serviceaccount secret ingress service deployment statefulset hpa job cronjob)
    # kubectl get "${resource_types[@]}" -o=name
    resources=$(kubectl api-resources --namespaced=false --verbs=list -o=name)
    kubectl get "${resources[@]}" -o=name
}

# Function : Export the YAML files from a cluster for a specific resource
# Description:
#   Exports the yaml representation of a specified Kubernetes resource to a file. 
#   The function takes one argument, resource_name, which is the name of the resource to be exported. 
#   Sets a local variable, resources_path, to a predefined path ($GIT_BASE_PATH/.resources), where the exported yaml files will be saved.
#   Creates a subdirectory within resources_path that corresponds to the resource type (if it exists) using mkdir -p "$resources_path/$(dirname $resource_name)". 
#   This allows for the exported yaml files to be organized by resource type, making it easier to find specific resources.
#   Use kubectl command to retrieve the yaml representation of the specified resource using the kubectl get -o=yaml $resource_name command. 
#   This command returns the yaml representation of the resource in the command line output. 
#   The output is then redirected to a file located at "$resources_path/$resource_name.yaml" using > operator, creating a new file or overwrite the file if it already exists.
# Parameters:
#   resource_name: The name of the resource to be exported.
function export_resource_yaml() {
    local resources_path="$GIT_BASE_PATH/.resources"
    local resource_name=$1
    mkdir -p "$resources_path/$(dirname $resource_name)"
    info "Generating YAML files for resource=$resource\n"
    kubectl get -o=yaml $resource_name > "$resources_path/$resource_name.yaml"
}


# Function : Export the YAML files from a cluster
# Description:
#   Export the YAML representation of resources in a cluster. 
#   Gets a list of resources in the cluster using the function "get_cluster_resources", and then iterates through each resource in the list. 
#   For each resource, it then calls the function "export_resource_yaml" and passes the resource as an argument, 
#   which exports the YAML representation of the resource to a file.
function export_yaml_from_cluster(){
    local cluster_resources=$(get_cluster_resources)
    for resource in $cluster_resources
    do
        export_resource_yaml $resource
    done
}
