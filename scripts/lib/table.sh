#!/usr/bin/env bash

# Function Print Line in yellow color
function print_line() {
local max_len=$1
  local line=$(printf -- "-%.0s" $(seq 1 $max_len))
  printf "\033[1m\033[33m%s\n\033[0m" "$line"
}

# Function print header
function print_header() {
  local max_namespace_len=$1
  local max_pod_len=$2
  local max_startup_time_len=$3
  printf "| \033[1m\033[33m%-*s\033[0m | \033[1m\033[33m%-*s\033[0m | \033[1m\033[33m%s\033[0m \n" $max_namespace_len "Namespace" $max_pod_len "Pod" "Startup Time"
}

# Function print rows
function print_row() {
  local namespace=$1
  local pod=$2
  local startup_time=$3
  local max_namespace_len=$4
  local max_pod_len=$5
  printf "| %-*s | %-*s | %s \n" $max_namespace_len "$namespace" $max_pod_len "$pod" "$startup_time"
}

function display_results() {
 local -a results=("$@")

  # Get the length of the longest string in each column
  local max_namespace_len=0
  local max_pod_len=0
  local max_startup_time_len=0
  for ((i=0; i<${#results[@]}; i+=3)); do
    local namespace="${results[i]}"
    local pod="${results[i+1]}"
    local startup_time="${results[i+2]}"
    if ((${#namespace} > max_namespace_len)); then
      max_namespace_len=${#namespace}
    fi
    if ((${#pod} > max_pod_len)); then
      max_pod_len=${#pod}
    fi
    if ((${#startup_time} > max_startup_time_len)); then
      max_startup_time_len=${#startup_time}
    fi
  done
  local max_len=$((max_namespace_len + max_pod_len + max_startup_time_len + 7))

  # Display the results in tabular format with lines
  print_line $max_len
  print_header $max_namespace_len $max_pod_len $max_startup_time_len
  print_line $max_len
  for ((i=0; i<${#results[@]}; i+=3)); do
    local namespace="${results[i]}"
    local pod="${results[i+1]}"
    local startup_time="${results[i+2]}"
    print_row "$namespace" "$pod" "$startup_time" $max_namespace_len $max_pod_len
  done
  print_line $max_len
}
