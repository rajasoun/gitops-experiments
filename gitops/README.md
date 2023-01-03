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
git checkout step-3.apps.podinfo
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
git checkout step-3.apps.podinfo
local-dev/iaac/env/env.sh teardown
local-dev/iaac/env/env.sh setup
source .env
```

## Install Flux onto your cluster

Run the bootstrap command:

```sh
  export BRANCH="step-3.apps.podinfo"
  flux bootstrap github \
    --owner=$GITHUB_USER \
    --repository=$GITHUB_REPO \
    --branch=$GITHUB_BRANCH \
    --path=./gitops/clusters/dev \
    --private=false \
    --personal=true
```

The bootstrap command above does following:

- Creates a git repository `gitops-experiments` on your GitHub account
- Adds Flux component manifests to the repository
- Deploys Flux Components to your Kubernetes Cluster
- installs Istio using the Istio base, istiod and gateway Helm charts
- waits for Istio control plane to be ready
- creates the Istio public gateway
- installs the nginx ingress controller
- installs the weave dashboard
- installs the cert-manager and letsencrypt cluster issuer
- install the podinfo app
- creates the podinfo ingress route using the Istio gateway


