#!/usr/bin/env bash

set -eu

YQ_VERSION="v4.30.6"
KUSTOMIZE_VERSION="4.5.7"
KUBECONFORM_VERSION="0.5.0"

function create_workspace() {
  if [ -z "${GITHUB_WORKSPACE:-}" ]; then
    echo "GITHUB_WORKSPACE is not set"
    exit 1
  fi

  if [ ! -d "$GITHUB_WORKSPACE" ]; then
    echo -e "GITHUB_WORKSPACE: $GITHUB_WORKSPACE"
    mkdir -p $GITHUB_WORKSPACE/bin
  fi
}

function install_tools(){
    create_workspace
    cd $GITHUB_WORKSPACE/bin
    curl -sL https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 -o yq
    chmod +x $GITHUB_WORKSPACE/bin/yq

    kustomize_url=https://github.com/kubernetes-sigs/kustomize/releases/download && \
    curl -sL ${kustomize_url}/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz | tar xz
    chmod +x $GITHUB_WORKSPACE/bin/kustomize

    curl -sL https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz | tar xz
    chmod +x $GITHUB_WORKSPACE/bin/kubeconform
}

install_tools
echo "$GITHUB_WORKSPACE/bin" >> $GITHUB_PATH
echo "$RUNNER_WORKSPACE/$(basename $GITHUB_REPOSITORY)/bin" >> $GITHUB_PATH

