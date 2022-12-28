# gitops-experiments

Guide to gain hands-on experience with GitOps using k3d Kubernetes cluster 

> We will use k3d for Kubernetes

## Setup Kubernetes cluster

Intall DevOps Tools, Kubernetes and Bootstap flux

```sh
WORKPSACE_PATH="$HOME/workspace/gitops"
[ ! -d  $WORKPSACE_PATH ] && mkdir -p $WORKPSACE_PATH
GIT_REPO_PATH="$HOME/workspace/gitops/gitops-experiments"
[ ! -d  $GIT_REPO_PATH ] && git clone https://github.com/rajasoun/gitops-experiments $WORKPSACE_PATH || cd $GIT_REPO_PATH/local-dev
./assist.sh setup 
./assist.sh test
./assist.sh status 
cd -
```

## About assist.sh

### setup

`./assist.sh setup` installs prerequisites tools, k3d cluster and populate .env file. It does the following:
1. Build .env file and populate it with required values, using `iaac/env/env.sh setup`
1. Installs required devops-tools using homebrew, using `iaac/prerequisites/prerequisite.sh setup`
1. Builds Kubernetes cluster using [k3d](https://k3d.io), using `iaac/k3d/k3d.sh setup`
1. Perform customization to the k9s, using `iaac/devops-tools/k9s/customize.sh setup`

### test

`./assist.sh test` tests the correctness of the cluster. It does the following:
1. Test prerequisite, using `iaac/prerequisites/prerequisite.sh test`
1. Test Kubernetes cluster using, `iaac/kubernetes/k3d/k3d.sh test`
1. Test k9s customization using `iaac/devops-tools/k9s/customize.sh test`

### check

> same as test in most cases. ToDo: Merge both

### status

`./assist.sh status` checks the status of the local dev environment. It does the following:
1. Prints status of prerequisite, using `iaac/prerequisites/prerequisite.sh status`
1. Prints status of  Kubernetes cluster, using `iaac/kubernetes/k3d/k3d.sh status`

### teardown

`./assist.sh teardown` teardown the entire local dev environment. It does the following:
1. Teardown Kubernetes cluster, using `iaac/kubernetes/k3d/k3d.sh teardown`
1. Teardown .env file, using `iaac/env/env.sh teardown`
1. Teardown k9s customization, using `iaac/devops-tools/k9s/customize.sh teardown`
1. Teardown prerequisite, using `iaac/prerequisites/prerequisite.sh teardown`.

> Note: This will delete the entire cluster and all the data. Use with caution. `iaac/prerequisites/prerequisite.sh teardown` is commented out by default. Uncomment it if you want to remove the prerequisite tools.

