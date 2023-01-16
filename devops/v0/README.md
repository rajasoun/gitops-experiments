# Deploy Nginx App Manually 

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

## Deploy Nginx App

1. Set Environment Variables
    ```bash
    export namespace="apps"
    export image="nginx:latest"
    export host="nginx.local.gd" 
    ```

1. Create a namespace
    ```bash
    kubectl create namespace $namespace
    ```

1. Deploy nginx app from cloud
    ```bash
    kubectl create deployment nginx --image=$image --port=80 -n $namespace
    ```

1. Expose nginx app as service
    ```bash
    kubectl expose deployment nginx --port=80 --target-port=80 --type=NodePort -n $namespace
    ```

1. Check status of  nginx app
    ```bash
    kubectl get all -n $namespace
    ```

1. Access service from localhost using port-forward
    ```bash
    scripts/wrapper.sh run port_forward "$namespace" "nginx" "8080:80" 
    http http://localhost:8080
    scripts/wrapper.sh run stop_port_forward "nginx"
    http http://localhost:8080
    ```

1. Deploy nginx ingress controller
    ```bash
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml 
    kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
    ```

1. Create ingress
    ```bash
    export ingress_name="nginx"
    kubectl create ingress $ingress_name --class=nginx --rule="nginx.local.gd/*=nginx:80" -n "$namespace"
    http http://nginx.local.gd 
    ```

