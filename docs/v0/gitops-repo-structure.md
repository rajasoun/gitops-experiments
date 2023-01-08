# Repository Structure 

**Managing Multiple Environmentss with GitOps**

The Git repository contains the following top directories inside **gitops** directory:

- **apps** dir contains Helm releases with a custom configuration per cluster
- **infrastructure** dir contains common infra tools such as ingress-nginx and cert-manager
- **clusters** dir contains the Flux configuration per cluster
- **validators** dir contains the Flux validators by service per cluster

```
├── apps
│   ├── <microservice> 
└── clusters
│    ├── dev
│    ├── staging
│    └── production
├── infrastructure
│   ├── configs
│   ├── controllers
│   └── istio
│       ├── system
│       └── gateway
└── validators
```

### Infrastructure

The infrastructure is structured into:

- **infrastructure/controllers/** dir contains namespaces and Helm release definitions for Kubernetes controllers
- **infrastructure/configs/** dir contains Kubernetes custom resources such as cert issuers and networks policies
- **infrastructure/istio/** dir contains istio deployment vi helm charts

```
./infrastructure/
├── configs
│   ├── cluster-issuers.yaml
│   ├── network-policies.yaml
│   └── kustomization.yaml
└── controllers
    ├── cert-manager.yaml
    ├── ingress-nginx.yaml
    ├── weave-gitops.yaml
    └── kustomization.yaml
```

In **clusters/production/infrastructure.yaml** we replace the Let's Encrypt server value to point to the production API

> Note that with ` interval: 12h` we configure Flux to pull the Helm repository index every twelfth hours to check for updates. If the new chart version that matches the `1.x` semver range is found, Flux will upgrade the release.

> Note that with `dependsOn` we tell Flux to first install or upgrade the controllers and only then the configs.
This ensures that the Kubernetes CRDs are registered on the cluster, before Flux applies any custom resources.

## Bootstrap staging and production

The clusters dir contains the Flux configuration:

```
./clusters/
├── dev
│   ├── apps.yaml
│   ├── infrastructure.yaml
│   └── istio.yaml
```

**clusters/staging/** dir we can have the Flux Kustomization definitions specific to staging 


### Access the Flux UI

To access the Flux UI on a cluster, first start port forwarding with:

```sh
kubectl -n flux-system port-forward svc/weave-gitops 9001:9001
```

Navigate to `http://localhost:9001` and login using the username `admin` and the password `flux`.

[Weave GitOps](https://docs.gitops.weave.works/) provides insights into your application deployments,
and makes continuous delivery with Flux easier to adopt and scale across your teams.
The GUI provides a guided experience to build understanding and simplify getting started for new users;
they can easily discover the relationship between Flux objects and navigate to deeper levels of information as required.

To generate a bcrypt hash please see Weave GitOps
[documentation](https://docs.gitops.weave.works/docs/configuration/securing-access-to-the-dashboard/#login-via-a-cluster-user-account). 

Note that on production systems it is recommended to expose Weave GitOps over TLS with an ingress controller and
to enable OIDC authentication for your organisation members.
To configure OIDC with Dex and GitHub please see this [guide](https://docs.gitops.weave.works/docs/guides/setting-up-dex/).

## Add clusters

Create new local cluster for staging.
    ```sh
    local-dev/iaac/kubernetes/k3d/k3d.sh teardown
    export ENV=staging
    local-dev/assist.sh setup
    ```

If you want to add a cluster to your fleet, first clone your repo locally:
Create a dir inside `clusters` with your cluster name:

    ```sh
    mkdir -p gitops/clusters/staging
    ```

Copy the sync manifests from staging:

    ```sh
    cp gitops/clusters/dev/istio.yaml gitops/clusters/staging
    cp gitops/clusters/dev/infrastructure.yaml gitops/clusters/staging
    cp gitops/clusters/dev/apps.yaml gitops/clusters/staging
    ```

You could create a staging overlay inside `apps`, make sure
to change the `spec.path` inside `clusters/staging/apps.yaml` to `path: ./gitops/apps/staging`. 

Refer https://github.com/fluxcd/flux2-kustomize-helm-example/blob/main/apps/staging/ for details 

Push the changes to the main branch:

    ```sh
    git checkout -b step-4.staging step-3.apps.podinfo
    git add -A && git commit -m "add staging cluster" && git push
    ```

Set the kubectl context and path to your dev cluster and bootstrap Flux using 

    ```sh
    export ENV=staging
    gitops/assist.sh setup
    ```

## Identical environments

If you want to spin up an identical environment, you can bootstrap a cluster
e.g. `dev-clone` and reuse the `dev` definitions.

Bootstrap the `dev-clone` cluster:

    ```sh
    git checkout -b dev-clone step-3.apps.podinfo
    sed -i '' -E   's/CLUSTER_NAME=dev/CLUSTER_NAME=dev-clone/' .env
    local-dev/assist.sh setup
    gitops/assist.sh setup
    ```

Pull the changes locally:
    ```sh
    git pull --rebase
    git push 
    ```

Create a `kustomization.yaml` inside the `clusters/dev-clone` dir

> Note that besides the `flux-system` kustomize overlay, we also include
the `infrastructure` and `apps` manifests from the dev dir.

Push the changes to the ranch:

```sh
git add -A && git commit -m "add dev clone" && git push
```

Tell Flux to deploy the production workloads on the `production-clone` cluster:

```sh
flux reconcile kustomization flux-system --context=dev-clone --with-source 
```


