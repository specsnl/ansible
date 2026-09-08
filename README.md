# ansible

[![Main](https://github.com/specsnl/ansible/actions/workflows/main.yml/badge.svg)](https://github.com/specsnl/ansible/actions/workflows/main.yml)

Multiple Ansible images with different kind of tools ready for K8s interactions.

## Pulling the images

```
docker pull ghcr.io/specsnl/ansible:latest
docker pull ghcr.io/specsnl/ansible/k8s:latest
```

## Task commands

Available [Task](https://taskfile.dev/#/) commands:

```
* build:                        Build both ansible and k8s images
* lint:                         Apply a Dockerfile linter (https://github.com/hadolint/hadolint)
* shell:                        Interactive shell with Ansible
* build:ansible:                Build the ansible image
* build:k8s:                    Build the k8s image
* deps:update:                  Update uv.lock (update all dependencies to their latest allowed versions)
* deps:upgrade:                 Update pyproject.toml (upgrade dependencies past their bounds and rewrite them)
* scripts:check-versions:       Check kubctl and kubectx versions
```

## Dependencies

Python dependencies are managed with [uv](https://docs.astral.sh/uv/): `pyproject.toml` holds the
constraints and `uv.lock` pins the resolved versions. SemVer packages are capped at their current
major, while CalVer tooling (`ansible-lint`, `yamllint`) only gets a lower bound.

- `task deps:update` — refresh `uv.lock` to the newest versions **within** the current constraints.
- `task deps:upgrade` — rewrite the constraints in `pyproject.toml` to move **past** their current
  bounds (`uv.lock` is updated along with them).

## Misc

**Workdir**: `/workspace`

**Environment variables**:

`KUBECONFIG_OVERRIDE`: If this env variable is set, it will put the contents of the variable in a (new) file at
`/root/.kube/context-override`. The path of the new file is then set as the value of `KUBECONFIG`-env.

<details><summary>Example:</summary>

```bash
docker run --rm --tty --env KUBECONFIG_OVERRIDE="`kind get kubeconfig --internal`" \
ghcr.io/specsnl/ansible/k8s:latest kubectl get nodes
```

Quote:
> kind is a tool for running local Kubernetes clusters using Docker container "nodes".

For more info see: https://github.com/kubernetes-sigs/kind
</details>
