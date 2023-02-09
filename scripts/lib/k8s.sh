#!/usr/bin/env bash

# List Ingress
function list_ingress(){
     HOST="$1"
     echo -e "HOST PATH NAMESPACE SERVICE PORT INGRESS REWRITE"
     echo -e "---- ---- --------- ------- ---- ------- -------"
     kubectl get --all-namespaces ingress -o json | \
        jq -r '.items[] | . as $parent | .spec.rules | select(length > 0) | .[] | select(.host==$ENV.HOST) | .host as $host | .http.paths[] | ( $host + " " + .path + " " + $parent.metadata.namespace + " " + .backend.service.name + " " + (.backend.service.port.number // .backend.service.port.name | tostring) + " " + $parent.metadata.name + " " + $parent.metadata.annotations."nginx.ingress.kubernetes.io/rewrite-target")' | \
        sort | column -s\  -t
}

# Watch Pods in a namespace
function watch_pods_in_namespace(){
    NAMESPACE="$1"
    # kubectl get pods -n "$NAMESPACE" -w
    watch kubectl -n"$NAMESPACE" get pods
}

# tail logs in a namespace
function tail_logs_in_namespace(){
    NAMESPACE="$1"
    POD="$2"
    CONTAINER="$3"
    #kubectl -n "$NAMESPACE" logs -f "$POD" "$CONTAINER"
    stern -n "$NAMESPACE" --exclude-container istio-proxy .
}

# wait till all pods are ready
function wait_till_all_pods_are_ready(){
    NAMESPACE="$1"
    kubectl wait -n "$NAMESPACE" --for=condition=ready pods --all --timeout=120s
}

# print Gateway URL 
function print_gateway_url(){
    export GATEWAY_HOST=$(kubectl -n istio-system get service istio-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    export GATEWAY_PORT=$(kubectl -n istio-system get service istio-gateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
    export SECURE_GATEWAY_PORT=$(kubectl -n istio-system get service istio-gateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
    export GATEWAY_URL=$GATEWAY_HOST:$GATEWAY_PORT
    pretty_print "${GREEN}Gateway URL : http://$GATEWAY_HOST:$GATEWAY_PORT${NC}\n"
}

# list all the istio resources
function list_istio_resources(){
    pretty_print "${YELLOW}Listing all the Istio resources${NC}\n"
    kubectl get all -n istio-system
    line_separator
    pretty_print "${YELLOW}Listing Istio Gateway${NC}\n"
    kubectl get gateways.networking.istio.io -A
    line_separator
    pretty_print "${YELLOW}Listing Istio VirtualServices${NC}\n"
    kubectl get virtualservices.networking.istio.io -A
    line_separator
}


# kubeshark hub 
function kubeshark_hub(){
    local filter="timestamp >= now()"
    exlude_health_probes=("/health" "/healthz" "/ready" "/readyz" "/live" "/livez" "/healthz/ready")
    for path in "${exlude_health_probes[@]}"; do
        filter="$filter and request.path != \"$path\""
    done
    exclude_flux_probes=("" "source-controller.flux-system" "weave-gitops.flux-system" "notification-controller.flux-system")
    for path in "${exclude_flux_probes[@]}"; do
        filter="$filter and dst.name  != \"$path\""
    done
    pretty_print "${BLUE}$filter${NC}"
    url_encoded_filter=$(curl -s -w '%{url_effective}\n' -G / --data-urlencode "=$filter" | cut -c 3-)
    open -a "Google Chrome" "http://localhost:8899?q=$url_encoded_filter"
}


# start port forwarding for a service
# Parameters:
#   $1 - namespace - e.g. "httpd-app"
#   $2 - service_name - e.g. "httpd"
#   $3 - port_mapping - e.g. "8080:80"
function port_forward(){
  local namespace="$1"
  local service_name="$2"
  local port_mapping="$3"

  # check parameters are not empty
    if [ -z "$namespace" ] || [ -z "$service_name" ] || [ -z "$port_mapping" ]; then
        echo -e "${RED}${BOLD}Invalid parameters${NC}"
        echo -e "${BLUE}Usage: scripts/wrapper.sh run port_forward  <namespace> <service_name> <port_mapping>${NC}"
        echo -e "${BOLD}Example:${NC} scripts/wrapper.sh run port_forward ingress-nginx ingress-nginx-controller 8080:80"
        return 1
    fi

  cmd="kubectl port-forward --namespace=$namespace service/$service_name $port_mapping &> ./logs/$service_name.log &" 
  pretty_print "${YELLOW}Starting Port Forward in Background${NC}\n"
  pretty_print "${BLUE}$cmd${NC}\n"

  #kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80 &> "./logs/$service_name.log" &
  kubectl port-forward "--namespace=$namespace" "service/$service_name" "$port_mapping" &> "./logs/$service_name.log" &
  server_pid=$!
  echo "pid=$server_pid" > "./logs/pids/$service_name.pid"
  pretty_print "${GREEN}Port Forward Started with pid=$server_pid${NC}\n"
  pretty_print "${BLUE}To Stop Execute -> scripts/wrapper.sh run stop_port_forward $service_name${NC}\n"
}

# stop port forwarding for a service
# Parameters:
#   $1 - service_name - e.g. "httpd"
function stop_port_forward(){
    service_name="$1"
    if [ -z "$service_name" ]; then
        echo -e "${RED}${BOLD}Invalid parameters${NC}"
        echo -e "${BLUE}Usage: scripts/wrapper.sh run stop_port_forward <service_name>${NC}"
        echo -e "${BOLD}Example:${NC} scripts/wrapper.sh run stop_port_forward ingress-nginx-controller"
        return 1
    fi
    source "./logs/pids/$service_name.pid"
    pretty_print "${YELLOW}Stopping Port Forward for service=$service_name with pid=$pid ${NC}\n"
    kill -9 $pid
    rm -fr "./logs/pids/$service_name.pid"
    rm -fr "./logs/$service_name.log"
    pretty_print "${GREEN}Port Forward Stopped${NC}\n"
}

# Function: patch ingress-nginx-controller type NodePort to LoadBalancer
function patch_nginx_ingress_controller(){
    pretty_print "${YELLOW}Patching ingress-nginx-controller type from NodePort to LoadBalancer${NC}\n"
    # Start by getting the name of the ingress-nginx-controller service
    kubectl get services -n ingress-nginx
    line_separator
    # Patch the service to change the type from NodePort to LoadBalance
    kubectl patch service ingress-nginx-controller -n ingress-nginx -p '{"spec":{"type":"LoadBalancer"}}'
    # Verify that the service type has been updated - Command should return LoadBalancer
    if [ $(kubectl get service ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.type}') == "LoadBalancer" ]; then
        pass "${GREEN}${BOLD}Patching ingress-nginx-controller type from NodePort to LoadBalancer - Passed${NC}\n"
    else
        fail "${RED}${BOLD}Patching ingress-nginx-controller type from NodePort to LoadBalancer - Failed${NC}\n"
    fi
    line_separator
    kubectl get service ingress-nginx-controller -n ingress-nginx
    line_separator
}


#  Initialize Load Balancer Env
function init_lb_env(){
    IP=$(kubectl --namespace istio-system get svc istio-ingressgateway  --output jsonpath="{.status.loadBalancer.ingress[0].ip}")
    HOSTNAME=$(kubectl --namespace istio-system get svc istio-ingressgateway --output jsonpath="{.status.loadBalancer.ingress[0].hostname}")

    if [[ $(ip_reachable $IP) == "false" ]]; then
        pretty_print "${YELLOW}IP $IP is not reachable.Switching to Local from .env\n${NC}"
        export $(grep -v "^#\|^$" .env | envsubst | xargs)
        export INGRESS_HOST_IP=$(dig +short $INGRESS_HOSTNAME)
        export BASE_HOST=$INGRESS_HOST_IP.nip.io
        pretty_print "${GREEN} INGRESS_HOSTNAME : $INGRESS_HOSTNAME | BASE_HOST : $BASE_HOST \n${NC}"
    fi
}

# Function: kubeconfig for a cluster in a aws region
function kube_config(){
    EKS_CONFIG_FILE="$GIT_BASE_PATH/.config/eks.env"
    AWS_PROFILE=${1:-"lcce-development"}
    AWS_REGION=${2:-"us-east-1"}
    CLUSTER=${3:-"Development"}

    echo -e "export AWS_PROFILE=$AWS_PROFILE" >  $EKS_CONFIG_FILE
    echo -e "export AWS_REGION=$AWS_REGION"   >> $EKS_CONFIG_FILE
    echo -e "export CLUSTER=$CLUSTER"          >> $EKS_CONFIG_FILE
    echo -e "export KUBECONFIG=$KUBECONFIG:~/.kube/config" >> $EKS_CONFIG_FILE

    export $(grep -v '^#' $EKS_CONFIG_FILE | xargs)
    aws eks update-kubeconfig --region $AWS_REGION  --name $CLUSTER
}

