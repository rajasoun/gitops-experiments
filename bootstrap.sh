#!/usr/bin/env bash

WORKPSACE_PATH="$HOME/workspace/gitops"
[ ! -d  $WORKPSACE_PATH ] && mkdir -p $WORKPSACE_PATH
GIT_REPO_PATH="$HOME/workspace/gitops/gitops-experiments"
[ ! -d  $GIT_REPO_PATH ] && git clone https://github.com/rajasoun/gitops-experiments $WORKPSACE_PATH || cd $GIT_REPO_PATH/local-dev