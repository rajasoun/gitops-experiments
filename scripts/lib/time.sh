#!/usr/bin/env bash

# Function to calculate the time difference between two times
function calculate_time_difference() {
  local start_time="$1"
  local end_time="$2"
  # Convert the start time to seconds
  local start_time_seconds=$(date -d "$start_time" +%s)
  # Convert the end time to seconds
  local end_time_seconds=$(date -d "$end_time" +%s)
  # Calculate the difference between the start time and the end time
  local time_diff=$((end_time_seconds - start_time_seconds))
  echo "$time_diff"
}

# Displays Time in mins and seconds
function display_time {
    local T=$1
    local D=$((T/60/60/24))
    local H=$((T/60/60%24))
    local M=$((T/60%60))
    local S=$((T%60))
    (( D > 0 )) && printf '%d days ' $D
    (( H > 0 )) && printf '%d hours ' $H
    (( M > 0 )) && printf '%d minutes ' $M
    (( D > 0 || H > 0 || M > 0 )) && printf 'and '
    printf '%d seconds\n' $S
}
