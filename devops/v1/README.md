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

kubectl get deployment nginx -o yaml -n apps

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.5.1/deploy/static/provider/cloud/deploy.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
kubectl apply -f devops/v1/all-in-one/nginx.yaml

kubectl get pods -l app=nginx -n $namespace -o jsonpath='{.items[*].metadata.name}' | awk '{print $NF}'

kubectl get pods -l app=nginx -n $namespace -o jsonpath='{.items[*].metadata.name}' | awk '{print $NF}' | xargs -I {} kubectl get pod -o yaml {} -n $namespace


kustomize build devops/v1/kustomize

kustomize build devops/v1/kustomize | kubectl apply  -f-


++++++++++

## Infrastucture
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.5.1/deploy/static/provider/cloud/deploy.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s

kustomize build devops/v1/kustomize/infrastructure | kubectl apply -f-
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s

## Application

kubectl apply -f devops/v1/all-in-one/nginx.yaml  

kustomize build devops/v1/kustomize/apps/nginx | kubectl apply -f-

kubectl wait --namespace apps --for=condition=ready pod --selector=app=nginx --timeout=120s


