#!/usr/bin/env bash

# Function : Get helm releases from a cluster
# Description:
#   This function gets the list of Helm releases in the cluster using the helm list -q command.
function get_helm_releases() {
    # check the time stamp of the file creation for $GIT_BASE_PATH/.resources/helm_releases.txt
    # if the file is older than 1 day, then delete the file and create a new one
    # else, use the existing file
    if [ -f $GIT_BASE_PATH/.resources/helm_releases.txt ]; then
        local file_creation_time=$(stat -c %Y $GIT_BASE_PATH/.resources/helm_releases.txt)
        local current_time=$(date +%s)
        local time_diff=$(($current_time - $file_creation_time))
        if [ $time_diff -gt 86400 ]; then
            info "Helm releases file is older than 1 day. Deleting the file and creating a new one."
            rm $GIT_BASE_PATH/.resources/helm_releases.txt
            helm list -q > $GIT_BASE_PATH/.resources/helm_releases.txt
        fi
    else
        helm list -q > $GIT_BASE_PATH/.resources/helm_releases.txt
    fi
    cat $GIT_BASE_PATH/.resources/helm_releases.txt
}

# Function: Get helm templates from a release
# Description:
#   This function gets the list of templates from a release using the helm get all $1 command.
#   The helm get all $1 command returns the list of templates in the release.
#   The grep templates command filters the output to only include the templates.
#   The awk '{print $3}' command prints the third column of the output, which is the name of the template.
function get_templates() {
    local release=$1
    helm get all $release | grep templates | awk '{print $3}'
}

# Function: Get helm manifest content from a release
# Description: 
#   Creates a directory called "manifests" within the "$resources_path/helm/$release" directory and 
#   Uses the grep and awk command to find the line numbers of each manifest in the "all.yaml" file. 
#   Then it uses the sed command to extract the content between these line numbers and write it to the corresponding manifest file.
# Parameters:
#   release: The name of the release
#   resources_path: The path to the resources directory
function extract_manifest_content() {
  local release=$1
  local resources_path=$2
  local template=$3
  local manifest_file=$(basename $template)
  local start_line_number=$(grep -n "$template" "$resources_path/$release/manifest.yaml" | awk -F: '{print $1}')
  local end_line_number=$(grep -n "templates/" "$resources_path/$release/manifest.yaml" | awk -F: '{print $1}' | grep -A1 $start_line_number | tail -1)
  # subtrcat 1 from the end_line_number to exclude the line with the next template
  end_line_number=$(($end_line_number - 1))
  sed -n "$start_line_number,$end_line_number p" "$resources_path/$release/manifest.yaml" > "$resources_path/$release/manifests/$manifest_file"
}

# Function: Split helm manifest by resource type
# Description:
#   This function splits the manifest file into separate files based on the resource type.
#   The function takes two arguments, release and resources_path.
#   The release argument is the name of the release.
#   The resources_path argument is the path to the resources directory.
# Parameters:
#   release: The name of the release
#   resources_path: The path to the resources directory
function split_helm_manifest_by_resource_type() {
    local release=$1
    local resources_path=$2
    mkdir -p "$resources_path/$release/manifests"
    for template in $(get_templates $release)
    do
        extract_manifest_content $release $resources_path $template
    done
}

# Function : Export helm Chart.yaml file from a cluster along with the values.yaml file and the reconstructed templates directory
# Description:
#   This function exports the helm Chart.yaml file from a cluster along with the values.yaml file and the reconstructed templates directory.
#   The function takes one argument, release, which is the name of the release to be exported.
#   Sets a local variable, resources_path, to a predefined path ($GIT_BASE_PATH/.resources), where the exported yaml files will be saved.
#   Creates a subdirectory within resources_path that corresponds to the release name (if it exists) using mkdir -p "$resources_path/helm/$release".
#   This allows for the exported yaml files to be organized by release name, making it easier to find specific releases.
#   Use helm get all $release command to retrieve the yaml representation of the specified release.
#   This command returns the yaml representation of the release in the command line output.
#   The output is then redirected to a file located at "$resources_path/helm/$release/$release.yaml" using > operator, 
#   creating a new file or overwrite the file if it already exists.
function export_helm_chart_for_release() {
    local resources_path="$GIT_BASE_PATH/.resources/helm"
    local release=$1
    mkdir -p "$resources_path/$release"
    # check when realease was last updated and 
    # compare it to the time the file $resources_path/$release/all.yaml was last updated
    # if the file is older than the release, then delete the file and create a new one
    
    # info "\nExporting Helm all for release : $release"
    # helm get all $release > "$resources_path/$release/all.yaml"
    info "Exporting Helm manifest for release : $release"
    helm get manifest $release > "$resources_path/$release/manifest.yaml"
    info "Exporting Helm manifest values for release : $release"
    helm get values $release > "$resources_path/$release/values.yaml"

    # info "Spliting manifest for release : $release"
    # split_helm_manifest_by_resource_type $release $resources_path

    info "Building kustomization.yaml for release : $release"
    cp $GIT_BASE_PATH/.resources/templates/kustomization.yaml $resources_path/$release/kustomization.yaml
}

# Function : Export the Helm charts from a cluster
# Description:
#   This function exports the Helm charts from a cluster.
#   Gets a list of Helm releases in the cluster using the function "get_helm_releases", and then iterates through each release in the list.
#   For each release, it then calls the function "export_helm_chart_for_release" and passes the release as an argument,
#   which exports the Helm chart for the release to a file.
function export_helm_charts_from_cluster(){
    info "Getting Helm releases from the cluster"
    local helm_releases=$(get_helm_releases)
    for release in $helm_releases
    do
        export_helm_chart_for_release $release
    done
}

