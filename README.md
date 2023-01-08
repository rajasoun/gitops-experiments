# gitops-experiments

Guide to gain hands-on experience with GitOps using k3d Kubernetes cluster 

## Laptop Setup

1. [Mac Setup](https://github.com/rajasoun/mac-onboard){:target="_blank" rel="noopener"}
2. [Windows Setup](https://github.com/rajasoun/win10x-onboard){:target="_blank" rel="noopener"}

> ### Technology Radar - DevSecOps Tools
> Refer to [DevSecOps Tools Technology Radar](./docs/DevSecOps-Tools-Radar.md) for details

## 1. Local Dev

**Refer to [Local Development Environment Managment](local-dev/README.md) for more details**


## 2. Gitops 

**Refer to [Gitops Experiments](gitops/README.md) for more details**


## Concepts 

1. Refer to [CI/CD](./docs/CI-CD.md) for more details
1. Refer to [GitOps](./docs/GitOps.md) for more detail
1. Refer to [Structuring Repository for Managing Multiple Environments](./docs/GitOps-Repo-Structure.md) for more details
1. Refer to [Istio](./docs/ISTIO.md) for more details
1. Refer to [Podinfo](./docs/Podinfo.md) for more details


Docs In Progress
---

1. Run VS Code User Defined Taks located in [tasks.json](./.vscode/tasks.json)  - CMD + SHIFT + T + R 
2. iterm2 Automation - Run `scripts/wrapper.sh watch` 
3. Wrapper to run fluc reconcile - Run `acripts/wrapper.sh run flux_reconcile`
4. Run `scripts/wrapper.sh run brew_install tilt` to install tilt in [tilt Brewfile](./local-dev/iaac/prerequisites/local/tilt/Brewfile) and Run `scripts/wrapper.sh run brew_uninstall tilt` to uninstall tilt
5. Run `scripts/wrapper.sh run check_brew_drift` to check drift on installed packages via Drift
6. Run `scripts/wrapper.sh run audit_trail` to update the audit trail