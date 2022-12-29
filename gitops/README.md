# Get Started with gitops using Flux

Bootstrap [Flux](https://fluxcd.io/) to a Kubernetes cluster.

## Before you begin

To follow the guide, you need the following:

- **A Kubernetes cluster**. We recommend [Kubernetes k3d](https://k3d.io) for trying Flux out in a local development environment.
- **A GitHub personal access token with repo permissions**. See the GitHub documentation on [creating a personal access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line).

## Objectives

- Bootstrap Flux on a Kubernetes Cluster

## Setup Flux with Github

```sh
git checkout step-0.bootstrap
gitops/assist.sh setup 
gitops/assist.sh test
gitops/assist.sh status 
```


## Watch and Monitor Logs

Run the bootstrap command:

```sh
watch flux get kustomizations
flux get kustomizations --watch
flux logs --all-namespaces --follow --tail=10
kubectl get gitrepositories -n flux-system
```

> Note: You can also use `scripts/iterm2/watch.sh` to watch the logs and flux status. 


## Test Infrastructure

1. Test weave dashboard is running
    ```sh
    gitops/validators/weave-dashboard.sh test
    ```
2. Test Nginx Ingress Controller is running with httpd 
    ```sh
    gitops/validators/httpd.sh test
    ```
3. Test app podinfo is running
    ```sh
    gitops/validators/podinfo.sh test
    ```

# For Reference 

Below section explains the steps that is wrapped in assist.sh script

## Check your Kubernetes cluster

Check you have everything needed to run Flux by running the following command:

```bash
flux check --pre
```

## Export your credentials

Export your GitHub personal access token and username:

```sh
gh auth login --hostname $GITHUB_BASE_URL --git-protocol https --web
export GITHUB_BASE_URL="github.com"
export GITHUB_USER=$(gh api "https://api.$GITHUB_BASE_URL/user" | jq .login | tr -d '"')
export GITHUB_TOKEN=$(gh auth token)
echo "GITHUB_USER=$GITHUB_USER | GITHUB_TOKEN=$GITHUB_TOKEN" 
```

## Install Flux onto your cluster

Run the bootstrap command:

```sh
  export BRANCH="step-0.bootstrap"
  flux bootstrap github \
    --owner=$GITHUB_USER \
    --repository=gitops-istio \
    --branch=$BRANCH \
    --path=./gitops/clusters/dev \
    --private=false \
    --personal=true
```

The bootstrap command above does following:

- Creates a git repository `gitops-istio` on your GitHub account
- Adds Flux component manifests to the repository
- Deploys Flux Components to your Kubernetes Cluster
- Configures Flux components to track the path `/gitops/clusters/dev` in the repository


