# ansible

[![Build Images](https://github.com/specsnl/ansible/workflows/main.yml/badge.svg)](https://github.com/specsnl/ansible/actions/workflows/main.yml)

Multiple Ansible images with different kind of tools ready for K8s interactions.

## Pulling the images

```
docker pull ghcr.io/specsnl/ansible:ansible-latest
docker pull ghcr.io/specsnl/ansible/k8s:latest
```

## Task commands

Available [Task](https://taskfile.dev/#/) commands:

```
* build:                        Build and run new.Dockerfile
* lint:                         Apply a Dockerfile linter (https://github.com/hadolint/hadolint)
* requirements:                 Update requirements.txt file
* a:shell:                      Interactive shell with Ansible
* scripts:check-versions:       Check kubctl and kubectx versions
```

## Misc

**Workdir**: `/ansible`

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
