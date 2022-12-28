# Service Mesh

A service mesh is a dedicated and configurable infrastructure layer that handles the communication between services without having to change the code in a microservice architecture. 

Using service mesh, it’s easy to handle security, manage traffic, control observability, and discover services.

## Istio
Istio is a service mesh — a modernized service networking layer that provides a transparent and language-independent way to flexibly and easily automate application network functions.

![Istio](https://miro.medium.com/max/1400/1*BZFuYZzV0e8GgQ3GZuCJHA.webp)


Istio manages traffic flows between services, enforces access policies, and aggregates telemetry data, all without requiring changes to the application code. 

Istio provides a uniform way to connect, manage, and secure microservices and enables developers to focus on delivering business value.

Istio simplifies service-to-service network operations like traffic management, authorization, and encryption, as well as auditing and observability.


## Istio Architecture

An Istio service mesh can be logically split into two components, a data plane and a control plane.

1. **Data Plane** — The Istio data plane is typically composed of Envoy proxies that are deployed as sidecars within each container on the Kubernetes pod.
1. **Control Plane** — The control plane manages and configures the proxies to route traffic. It also stores and manages the Istio configuration.

Istio has 2 core component -

1. **Envoy** - Proxy Component, deployed as sidecar to interact with interact with data plane traffic.
1. **Istiod** - Istiod converts high level routing rules that control traffic behaviour into Envoy-specific configurations and propagates them to the sidecars at runtime.

![Istio Architecture](https://istio.io/latest/docs/ops/deployment/architecture/arch.svg)

Istio **Control plane functionality** is consolidated into a single binary called Istiod. This contains a few components.

1. Pilot - Responsible for configuring the data plane and communicating with the Envoy sidecars.
1. Citadel - Allows developers to build zero-trust environments based on service identity rather than network controls. It helps you in securing communication between k8s components.
1. Galley - Provides configuration management services for Istio. It’s the interface for the underlying APIs with which the Istio control plane interacts. If new policies come in picture then Galley validates, process and deploy them.

Istio **Data plane** components are made of Envoy Proxies. These are layer 7 proxy. All traffic moves through these Envoy proxies. Istio provides few addons for monitoring and visualising this data. Responsible for :

1. Service Discovery
1. Health Checks
1. Routing
1. Load balancing
1. Authentication
1. Authorisation
1. Observability


## Comparision with other Service Meshes

![istio-vs-others](https://miro.medium.com/max/1400/1*C-w_7dhU9A7BnuFIB8EQsg.webp)




## Istio Installation with Helm

Follow this guide to install and configure an Istio mesh using [Helm](https://helm.sh/docs/).

The Helm charts used in this guide are the same underlying charts used when installing Istio via [Istioctl](https://istio.io/latest/docs/setup/install/istioctl/).

> Istio Installation with Helm  is currently considered [alpha](https://istio.io/latest/docs/releases/feature-stages/).

### Install Istio via Helm

Reference: [Istio Helm Chart](https://istio.io/latest/docs/setup/install/helm/)

1. Create a **namespace** istio-system for Istio components using [namespace.yaml](./components/namespace.yaml)
2. Install the **Istio base chart** which contains cluster-wide resources used by the Istio control plane.
2. Install the **Istio discovery chart** which contains the Istio control plane components.
3. Install the **Istio ingress gateway chart** which contains the Istio ingress gateway components.

## Verify Istio Installation

1. Status of the installation can be verified using Helm:

    ```bash
    helm status istiod -n istio-system
    ```

2. Verify that the Istio control plane components are deployed using the following command:

    ```bash
    kubectl get pods -n istio-system
    ```

    The output should be similar to the following:

    ```bash
    NAME                                    READY   STATUS    RESTARTS   AGE
    istio-ingressgateway-5c8b4f4c4c-7z2jg   1/1     Running   0          2m
    istiod-7f9b9f4d9c-6x7x7                 1/1     Running   0          2m
    ```

3. Watch for the Helm releases being installed:

    ```bash
    watch flux get helmreleases --all-namespaces
    ```


