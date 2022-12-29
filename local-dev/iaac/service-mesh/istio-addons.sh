#!/usr/bin/env bash

GIT_BASE_PATH=$(git rev-parse --show-toplevel)
SCRIPT_LIB_DIR="$GIT_BASE_PATH/scripts/lib"

function setup(){
    # Install istio addons
    kubectl apply --filename https://raw.githubusercontent.com/istio/istio/master/samples/addons/kiali.yaml
    kubectl apply --filename https://raw.githubusercontent.com/istio/istio/master/samples/addons/jaeger.yaml
    kubectl apply --filename https://raw.githubusercontent.com/istio/istio/master/samples/addons/grafana.yaml
    kubectl apply --filename https://raw.githubusercontent.com/istio/istio/master/samples/addons/prometheus.yaml

    sleep 10
    kubectl wait -n istio-system --for=condition=ready pods --all --timeout=120s
    echo -e "${GREEN}istio addon Installation Sucessfull${NC}"
}

function teardown(){
    # Teardown istio addons
    kubectl delete --filename https://raw.githubusercontent.com/istio/istio/master/samples/addons/kiali.yaml
    kubectl delete --filename https://raw.githubusercontent.com/istio/istio/master/samples/addons/jaeger.yaml
    kubectl delete --filename https://raw.githubusercontent.com/istio/istio/master/samples/addons/grafana.yaml
    kubectl delete --filename https://raw.githubusercontent.com/istio/istio/master/samples/addons/prometheus.yaml
    echo -e "${GREEN}istio addon teardown Sucessfull${NC}"
}

source "${SCRIPT_LIB_DIR}/main.sh" $@

