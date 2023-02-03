#!/usr/bin/env bash

# Function Get the length of the longest string in each column
function get_max_lengths() {
  local -a results=("$@")

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

  echo "$max_namespace_len $max_pod_len $max_startup_time_len"
}

display_results() {
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

  # Display the results in tabular format with lines
  local line=$(printf -- "-%.0s" $(seq 1 $((max_namespace_len + max_pod_len + max_startup_time_len + 7))))
  printf "\033[1m\033[33m%s\n\033[0m" "$line"
  printf "| \033[1m\033[33m%-*s\033[0m | \033[1m\033[33m%-*s\033[0m | \033[1m\033[33m%s\033[0m \n" $max_namespace_len "Namespace" $max_pod_len "Pod" "Startup Time"
  printf "\033[1m\033[33m%s\n\033[0m" "$line"
  for ((i=0; i<${#results[@]}; i+=3)); do
    local namespace="${results[i]}"
    local pod="${results[i+1]}"
    local startup_time="${results[i+2]}"
    printf "| %-*s | %-*s | %s \n" $max_namespace_len "$namespace" $max_pod_len "$pod" "$startup_time"
  done
  printf "\033[1m\033[33m%s\n\033[0m" "$line"
}
