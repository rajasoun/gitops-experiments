#!/usr/bin/env bash

# Function to get a list of all namespaces
function get_all_namespaces() {
  kubectl get namespaces -o json | jq -r '.items[].metadata.name'
}

# Function to get list of all pods across all namespaces
function get_all_pods() {
  kubectl get pods -A -o json | jq '.items[].metadata | {namespace: .namespace, name: .name}'
}

# Function to get a list of all pods in a namespace
function get_pods_in_namespace() {
  local namespace="$1"
  
  kubectl get pods -n "$namespace" -o json | jq -r '.items[].metadata.name'
}

# Function to get the start time of a pod
function get_pod_start_time() {
  local pod_name="$1"
  local namespace="$2"
  
  kubectl describe pods -n "$namespace" "$pod_name" | grep "Start Time" | awk '{$1=""; print substr($0,8)}'
}

# Function to get the time a pod reached the "Running" state
function get_pod_started_time() {
  local pod_name="$1"
  local namespace="$2"
  
  kubectl describe pods -n "$namespace" "$pod_name" | grep "Started" | awk '{$1=""; print substr($0,2)}'
}

# Function to calculate the time it took for a pod to reach the "Running" state
function calculate_startup_time() {
  local pod_name="$1"
  local namespace="$2"
  
  # Get the Pod start time
  local start_time=$(get_pod_start_time "$pod_name" "$namespace")  
  # Get the time pod reached the "Running" state
  local time_started=$(get_pod_started_time "$pod_name" "$namespace")

  # Calculate the difference between the start time and the time_started
  local time_diff=$(calculate_time_difference "$start_time" "$time_started")
  
  # Convert the difference to human-readable format
  display_time "$time_diff"
}

# Function to calculate and display the startup times for all pods in all namespaces
function calculate_all_startup_times() {
  # Get a list of all namespaces
  local namespaces=$(get_all_namespaces)
  # Array to store the results
  local results=()

  # Loop through each namespace
  for namespace in $namespaces; do
    # Get a list of all pods in the namespace
    local pods=$(get_pods_in_namespace "$namespace")
    
    # Loop through each pod
    for pod in $pods; do
      # Calculate the startup time for the pod
      local startup_time=$(calculate_startup_time "$pod" "$namespace")
      # Add the result to the array
      results+=("$namespace" "$pod" "$startup_time")
    done
  done

  # Display the results
  display_results "${results[@]}"
}