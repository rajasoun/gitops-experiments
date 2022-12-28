# gitops-local-dev

Guide to gain hands-on experience with GitOps using k3d Kubernetes cluster 
We will use k3d for Kubernetes

## Setup

1. Fork this repository and clone it:
    ```sh
    git clone https://github.com/rajasoun/gitops-local-dev
    cd gitops-local-dev
    ```
2. Run `./assist.sh setup` to install prerequisites tools, k3d cluster and populate .env file

Script will do the following:
1. Prepare .env file and populate it with required values. Invoke `iaac/env/env.sh setup`
2. Install required devops-tools using homebrew. Invoke `iaac/prerequisites/prerequisite.sh setup`
3. Kubernetes cluster using [k3d](https://k3d.io). Invoke `iaac/k3d/k3d.sh setup`

## Test and Status 

1. Run `./assist.sh test` to test the cluster
2. Run `./assist.sh status` to check the status of the cluster

## Teardown

1. Run `./assist.sh teardown` to teardown the cluster
