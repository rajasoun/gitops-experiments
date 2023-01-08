# gitops-experiments

Guide to gain hands-on experience with GitOps using k3d Kubernetes cluster 

## Laptop Setup

1. [Mac Setup][mac_setup]
2. [Windows Setup][win_setup]

> ### Technology Radar - DevSecOps Tools
> Refer to [DevSecOps Tools Technology Radar][tech_radar] for details

## 1. Local Dev

**Refer to [Local Development Environment Managment][local_dev] for more details**


## 2. Gitops 

**Refer to [Gitops Experiments][git_ops] for more details**


## Concepts 

1. Refer to [CI/CD][ci_cd] for more details
1. Refer to [GitOps][git_ops] for more detail
1. Refer to [Structuring Repository for Managing Multiple Environments][repo_structure] for more details
1. Refer to [Istio][istio] for more details
1. Refer to [Podinfo][podinfo] for more details


Docs In Progress
---

1. Run VS Code User Defined Taks located in [tasks.json][tasks_json]  - CMD + SHIFT + T + R 
2. iterm2 Automation - Run `scripts/wrapper.sh watch` 
3. Wrapper to run fluc reconcile - Run `acripts/wrapper.sh run flux_reconcile`
4. Run `scripts/wrapper.sh run brew_install tilt` to install tilt in [tilt Brewfile][local_brew_file] and Run `scripts/wrapper.sh run brew_uninstall tilt` to uninstall tilt
5. Run `scripts/wrapper.sh run check_brew_drift` to check drift on installed packages via Drift
6. Run `scripts/wrapper.sh run audit_trail` to update the audit trail

[win_setup]: https://github.com/rajasoun/win10x-onboard
[mac_setup]: https://github.com/rajasoun/mac-onboard
[tech_radar]: ./docs/DevSecOps-Tools-Radar.md
[local_dev]: local-dev/README.md
[git_ops]: gitops/README.md
[ci_cd]: ./docs/CI-CD.md
[git_ops]: ./docs/GitOps.md
[repo_structure]: ./docs/GitOps-Repo-Structure.md
[istio]: ./docs/ISTIO.md
[podinfo]: ./docs/Podinfo.md
[tasks_json]: ./.vscode/tasks.json
[local_brew_file]: ./local-dev/iaac/prerequisites/local/tilt/Brewfile