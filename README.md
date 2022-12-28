# gitops-experiments

Guide to gain hands-on experience with GitOps using k3d Kubernetes cluster 

> We will use k3d for Kubernetes

## Setup Kubernetes cluster

1. Create workspace directory and clone git repo

    ```sh
    WORKPSACE_PATH="$HOME/workspace/gitops"
    GIT_REPO_PATH="$HOME/workspace/gitops/gitops-experiments"
    [ ! -d  $WORKPSACE_PATH ] && mkdir -p $WORKPSACE_PATH
    [ ! -d  $GIT_REPO_PATH ] && git clone https://github.com/rajasoun/gitops-experiments $WORKPSACE_PATH 
    ```

2. Setup local development environment

    ```sh
    local-dev/assist.sh setup
    ```

3. Test local development environment

    ```sh
    local-dev/assist.sh test
    ```

4. Check the status of the local development environment

    ```sh
    local-dev/assist.sh status
    ```
