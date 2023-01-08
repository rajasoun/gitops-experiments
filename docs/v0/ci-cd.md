# CI/CD 

Continuous integration (CI) and continuous delivery (CD) are software development practices that require developers to frequently merge their code changes into a central repository where builds and tests are run.

## CI/CD pipelines

**Continuous Integration:**
1. Software development practice where developers regularly merge their code changes into a central repository, after which automated builds and tests are run.
1. Entails both an automation component (e.g., a CI or build service) and a cultural component (e.g., learning to integrate frequently).
1. A continuous integration tooling ecosystem must automatically build and runs unit/integration tests, code quality checks, security checks, secrets check on the new code changes to immediately surface any errors.


**Continuous Delivery:**
1. Software development practice where code changes are automatically prepared for a release to production
1. Expands upon continuous integration by deploying all code changes to a testing environment and/or a production environment after the build, unit test and code quality check stage
1. Continuous delivery mandates automated testing (UI testing, load testing, integration testing, API reliability testing,) beyond unit tests and code quality checks.
1. With continuous delivery, every code change is built, tested, and then pushed to a non-production testing or staging environment. There can be multiple, parallel test stages before a production deployment. 
1. In continuous delivery, there is an explicit manual approval to deploy to Production

**Continuous Deployment:**
1. In continuous deployment, there will no explicit manual approval to deployment to Production is required


## CI/CD pipeline 

Continous Integration and Continous Deployment pipeline in mermaid


```mermaid
graph LR;
  classDef plain fill:#ddd,stroke:#fff,stroke-width:4px,color:#000;
  classDef blue_fill fill:#326ce5,stroke:#fff,stroke-width:4px,color:#fff;
  classDef ci fill:#fff,stroke:#bbb,stroke-width:2px,color:#326ce5;

  Dev([Dev])-. Check In <br> code .->Github[Git Push];
  Github-->|Quality Check|automated_tests[Automated Tests];
    subgraph ci[Continous Integration]
        Github;
        subgraph Automation Tests
            automated_tests-->unit_test[Unit Test];
            unit_test-->api_test[API/e2e Test];
            automated_tests-->security[Security];
            automated_tests-->code_qaulity[Code Quality];
            on_success[On Success];
        end
    on_success-->build_image[Build Image];
    build_image-->push_image[Push Image];
    end
    push_image-->container_registry[Container Registry];

    DevOps([DevOps])-. Deploys <br> Image .->Microservice[K8s Deployer];
    container_registry-->Microservice;

    subgraph Continous Delivery
        Microservice-->|Deploy|dev[Dev];
        dev-->|Staging|staging[Staging];
        staging-->|production|production[Production];
    end
    
    class Github,automated_tests,unit_test,code_quality,security,secrets,build,container_registry,api_test,code_qaulity,on_success,build_image,push_image blue_fill;
    class Microservice,dev,staging,production blue_fill;
```


## CI/CD pipeline with Kubernetes

With Kubernetes, it’s easy to implement an in-cluster CI/CD pipeline. 
You can have CI software create the container image representing your application and store it in a container image registry. 

Afterward, a Git workflow such as a pull request can change the Kubernetes manifests illustrating the deployment of your apps and start a CD sync loop.


![Git Ops Cookbook](https://developers.redhat.com/sites/default/files/gocb_0102.png)

[GitOps](./GitOps.md) is a way to do CI/CD on Kubernetes. It uses Git as a single source of truth for declarative infrastructure and applications.

