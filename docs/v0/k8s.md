# Kubernetes

## About Kubernetes

[Kubernetes][k8s_docs] is an open-source system for automating deployment, scaling, and management of containerized applications. 

It groups containers that make up an application into logical units for easy management and discovery.


## Kubernetes Terminologies

- **Cluster** - Set of nodes (physical or virtual machines) that are grouped together to provide the resources needed to run applications. It is is used for running and managing containerized applications across multiple nodes in a **distributed system**.
- **Node** - Physical or Virtual machine in a Kubernetes cluster that runs the Kubernetes processes necessary to make that node a part of the cluster. It sis used to run containerized applications.
- **Namespace** - Logical grouping of objects and resources within a Kubernetes cluster. It is used to create a logical boundary for grouping together resources such as pods, services, and replication controllers.
- **Pod** -  Basic building block of Kubernetes, representing a single instance of an application, process, or service. It is used for providing logical collection of one or more containers that share the same network, storage, and namespace.
- **Service** - Logical grouping of pods that provide a single, stable endpoint for external clients to access the application or service. It is used for network load balancing and service discovery for applications running on Kubernetes.
- **Deployment** -  Logical abstraction that manages a set of identical pods, providing declarative updates to the desired state of the pods.Deployments are used to manage the lifecycle of an application or service and handle things like rolling updates.
- **ReplicaSet** - A Kubernetes ReplicaSet that ensures that a specified number of pod replicas are running at any one time.
- **Ingress** - A Kubernetes Ingress that exposes HTTP and HTTPS routes from outside the cluster to services within the cluster. Traffic routing is controlled by rules defined on the Ingress resource.
- **ConfigMap** - A Kubernetes ConfigMap that lets you decouple environment-specific configuration from your container images so that your applications are easily portable.
- **Label** -  A label is a key-value pair that can be used to attach arbitrary metadata to Kubernetes objects. 
- **Secret** - A Kubernetes Secret that lets you store and manage sensitive information, such as passwords, OAuth tokens, and ssh keys. Storing confidential information in a Secret is safer and more flexible than putting it verbatim in a Pod definition or in a container image.
- **ServiceAccount** - A Kubernetes ServiceAccount provides an identity for processes that run in a Pod.
- **Role** - A Kubernetes Role contains rules that represent a set of permissions. Permissions are purely additive (there are no “deny” rules).

## kind:pod vs kind:deployment 

The choice between using a pod or a deployment in Kubernetes depends on the requirements of your application.

A pod is the most basic unit of a Kubernetes deployment, and is typically used for simple, single-container applications. Pods are ephemeral, meaning they can be created, destroyed, and recreated easily. They are great for applications that require minimal configuration and don’t need to be scaled or updated often.

A deployment is a higher-level resource that manages a set of pods and provides more configuration options. It allows for automatic scaling and rolling updates, which makes it ideal for applications that require more complex configurations, such as multiple containers or frequent updates.

## Ask GPT

In Visual studio code, Open New Terminal and run the following commands

    ```bash
    make -f ask-gpt/Makefile build
    bin/ask-gpt "what is k3d" 
    bin/ask-gpt "what is k9s" 
    ```

## Kubernetes Cluster

In Visual studio code, Open New Terminal and run the following commands

    ```bash
    local-dev/assist.sh setup
    local-dev/assist.sh status
    kubectl get --raw '/readyz?verbose'
    ```

[k8s_docs]: https://kubernetes.io/docs/home/