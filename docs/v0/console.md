# Documentation Pointers

1. [**GitHub** Project][git_repo]
1. **Setup** - [Mac][mac_setup] | [Win][win_setup]
1. **Concepts** - [Pointers][quick_ref]
    - Tools Assembly & Radar
    - Infrastructure as Code (IaC)
    - Continous Integration (CI)
    - Continous Delivery (CD)
    - Continous Deployment (CD)
    - GitOps
    - Service Mesh

## Kubernetes Key Concepts

In Visual studio code, Open New Terminal and run the following commands

    ```bash
    local-dev/assist.sh setup
    local-dev/assist.sh status
    kubectl get --raw '/readyz?verbose'
    ```

## Ask GPT

In Visual studio code, Open New Terminal and run the following commands

    ```bash
    cd ask-gpt
    go build -o bin/
    cd -
    ask-gpt/bin/ask-gpt "what is k3d" 
    ```
---

[git_repo]: https://github.com/rajasoun/gitops-experiments
[mac_setup]: https://github.com/rajasoun/mac-onboard
[win_setup]: https://github.com/rajasoun/win10x-onboard
[quick_ref]: https://github.com/rajasoun/gitops-experiments/blob/main/docs/v0/quick.md

