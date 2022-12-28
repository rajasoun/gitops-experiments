# gitops-experiments

Guide to gain hands-on experience with GitOps using k3d Kubernetes cluster 

> We will use k3d for Kubernetes

## Setup Kubernetes cluster

Intall DevOps Tools, Kubernetes and Bootstap flux

```sh
WORKPSACE_PATH="$HOME/workspace/gitops"
GIT_REPO_PATH="$HOME/workspace/gitops/gitops-experiments"
[ ! -d  $WORKPSACE_PATH ] && mkdir -p $WORKPSACE_PATH
[ ! -d  $GIT_REPO_PATH ] && git clone https://github.com/rajasoun/gitops-experiments $WORKPSACE_PATH || cd $GIT_REPO_PATH/local-dev
./assist.sh setup 
./assist.sh test
./assist.sh status 
cd -
```
