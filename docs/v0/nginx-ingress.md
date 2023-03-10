# Ingress

An API object that manages external access to the services in a cluster, typically HTTP.

An Ingress may be configured to give Services
- externally-reachable URLs,
- load balance traffic,
- terminate SSL / TLS and
- offer name-based virtual hosting


## What is an Ingress?**

In Kubernetes, an Ingress is an object that allows access to your Kubernetes services from outside the Kubernetes cluster. 
You configure access by creating a collection of rules that define which inbound connections reach which services.

 Example where an Ingress sends all its traffic to one Service

```mermaid
graph LR;
  classDef plain fill:#ddd,stroke:#fff,stroke-width:4px,color:#000;
  classDef k8s fill:#326ce5,stroke:#fff,stroke-width:4px,color:#fff;
  classDef cluster fill:#fff,stroke:#bbb,stroke-width:2px,color:#326ce5;

  client([client])-. Ingress-managed <br> load balancer .->ingress[Ingress];
  ingress-->|routing rule|service[Service];
  subgraph cluster
  ingress;
  service-->pod1[Pod];
  service-->pod2[Pod];
  end
  
  class ingress,service,pod1,pod2 k8s;
  class client plain;
  class cluster cluster;
``` 

With an Ingress, you can easily set this up without creating a bunch of LoadBalancers or exposing each service on the Node.

Which leads us to the next point…

## Kubernetes Ingress vs LoadBalancer vs NodePort


These options all do the same thing. 

1. Expose a service to external network requests.
1. Send a request from outside the Kubernetes cluster to a service inside the cluster.

### NodePort

![NodePort](https://matthewpalmer.net/kubernetes-app-developer/articles/nodeport.png)

`NodePort` is a configuration setting you declare in a service’s YAML. 

* Set the service spec’s `type` to `NodePort`. 
* Kubernetes will allocate a specific port on each Node to that service, and 
* Any request to your cluster on that port gets forwarded to the service.

This is cool and easy, it’s just not super robust. 
You don’t know what port your service is going to be allocated, and the port might get re-allocated at some point.

### LoadBalancer

![loadbalancer in kubernetes](https://matthewpalmer.net/kubernetes-app-developer/articles/loadbalancer.png)

You can set a service to be of type `LoadBalancer` the same way you’d set `NodePort`— specify the `type` property in the service’s YAML. 

There needs to be some external load balancer functionality in the cluster, typically implemented by a cloud provider.

This is typically heavily dependent on the cloud provider or Service Mesh like Istio. 

It creates a Network Load Balancer with an IP address that you can use to access your service.

Every time you want to expose a service to the outside world, you have to create a new LoadBalancer and get an IP address.

### Ingress

![ingress in kubernetes](https://matthewpalmer.net/kubernetes-app-developer/articles/ingress.png)

`NodePort` and `LoadBalancer` let you expose a service by specifying that value in the service’s `type`. Ingress, on the other hand, is a completely independent resource to your service. 
You declare, create and destroy it separately to your services.

This makes it decoupled and isolated from the services you want to expose. 

It also helps you to consolidate routing rules into one place.

The one downside is that you need to configure an Ingress Controller for your cluster. But that’s pretty easy—in this example, we’ll use the Nginx Ingress Controller.

### Nginx Ingress Controller

Reference - https://matthewpalmer.net/kubernetes-app-developer/articles/kubernetes-ingress-guide-nginx-example.html

### Summary

A Kubernetes Ingress is a robust way to expose your services outside the cluster. It lets you consolidate your routing rules to a single resource, and gives you powerful options for configuring these rules.
