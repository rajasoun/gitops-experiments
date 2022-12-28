#!/usr/bin/env bash 

SCRIPT_LIB_DIR="$(dirname "${BASH_SOURCE[0]}")"

function list_ingress(){
     HOST="$1"
     check_host
     echo -e "HOST PATH NAMESPACE SERVICE PORT INGRESS REWRITE"
     echo -e "---- ---- --------- ------- ---- ------- -------"
     kubectl get --all-namespaces ingress -o json | \
        jq -r '.items[] | . as $parent | .spec.rules | select(length > 0) | .[] | select(.host==$ENV.HOST) | .host as $host | .http.paths[] | ( $host + " " + .path + " " + $parent.metadata.namespace + " " + .backend.service.name + " " + (.backend.service.port.number // .backend.service.port.name | tostring) + " " + $parent.metadata.name + " " + $parent.metadata.annotations."nginx.ingress.kubernetes.io/rewrite-target")' | \
        sort | column -s\  -t
}

function watch_pods_in_namespace(){
    NAMESPACE="$1"
    # kubectl get pods -n "$NAMESPACE" -w
    watch kubectl -n"$NAMESPACE" get pods
}

function tail_logs_in_namespace(){
    NAMESPACE="$1"
    POD="$2"
    CONTAINER="$3"
    #kubectl -n "$NAMESPACE" logs -f "$POD" "$CONTAINER"
    stern -n "$NAMESPACE" --exclude-container istio-proxy .
}

function install_istio_if_not(){
    # Check if istio is installed
    if ! kubectl get namespace istio-system > /dev/null 2>&1; then
        echo -e "${RED}Istio is not installed. Auto Installing istio before installing the app${NC}"
        scripts/service-mesh/istio.sh setup 
        export PATH=$HOME/.istioctl/bin:$PATH 
    fi
}

function wait_till_all_pods_are_ready(){
    NAMESPACE="$1"
    kubectl wait -n "$NAMESPACE" --for=condition=ready pods --all --timeout=120s
}