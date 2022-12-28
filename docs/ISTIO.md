# Istio Installation with Helm

Follow this guide to install and configure an Istio mesh using [Helm](https://helm.sh/docs/).

The Helm charts used in this guide are the same underlying charts used when installing Istio via [Istioctl](https://istio.io/latest/docs/setup/install/istioctl/).

> Istio Installation with Helm  is currently considered [alpha](https://istio.io/latest/docs/releases/feature-stages/).

## Install Istio via Helm

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


