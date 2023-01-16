# Deploy Nginx App

Deploy Ngix App using Manifest Files

## Pre-requisites

1. DevSecOps Tools Setup are Done !!!
    ```bash
    local-dev/iaac/prerequisites/prerequisite.sh test 
    ```
1. Local Kubernetes Cluster is Done !!!
    ```bash
    kubectl get --raw '/readyz?verbose'
    k3d cluster list
    local-dev/iaac/kubernetes/k3d/k3d.sh status
    ```

## Nginx App using Manifest Files

1. Setup Nginx App using Manifest Files
    ```bash
    devops/v1/all-in-one/app.sh setup
    ```

1. Teardown Nginx App using Manifest Files
    ```bash
    devops/v1/all-in-one/app.sh setup
    ```

1. Status of Nginx App 
    ```bash
    devops/v1/all-in-one/app.sh status
    ```

1. Test Nginx App 
    ```bash
    devops/v1/all-in-one/app.sh test
    ```

