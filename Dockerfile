# syntax=docker/dockerfile:1
# check=error=true

# Latest version: https://github.com/astral-sh/uv/releases
FROM ghcr.io/astral-sh/uv:0.11.19 AS uv

# Latest version: https://hub.docker.com/_/python/tags?name=3.14.5-alpine
FROM python:3.14.5-alpine3.23 AS ansible

ENV HOME=/home

WORKDIR /ansible

COPY --from=uv /uv /usr/local/bin/uv

COPY pyproject.toml uv.lock ./

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# hadolint ignore=DL3018
RUN apk add --no-cache --no-progress \
        bash \
        curl \
        openssl \
        git \
        openssh-client-default \
        jq \
        gnupg \
        pass \
        rsync \
        sshpass \
        sudo \
        unzip \
        docker-cli \
    && chmod 777 -R "$HOME" \
    && seq 500 1999 | awk '{printf "user:x:%d:%d::/home:/sbin/nologin\n",$1,$1}' >> /etc/passwd \
    && uv sync --frozen --no-dev \
    && rm pyproject.toml uv.lock

COPY files/ansible /

ENV PATH="/ansible/.venv/bin:$PATH"

FROM ansible AS k8s

ARG TARGETARCH

# Latest version of Kubectl at the moment: https://storage.googleapis.com/kubernetes-release/release/stable.txt
ARG KUBECTL_VERSION=v1.31.0
ARG KUBECTL_SHA256_AMD64=7c27adc64a84d1c0cc3dcf7bf4b6e916cc00f3f576a2dbac51b318d926032437
ARG KUBECTL_SHA256_ARM64=f42832db7d77897514639c6df38214a6d8ae1262ee34943364ec1ffaee6c009c

# Latest version of kubectx/kubens at the moment: https://api.github.com/repos/ahmetb/kubectx/releases/latest
ARG KUBECTX_VERSION=v0.11.0
ARG KUBECTX_SHA256_AMD64=08e031c54fbffb3f100e904e4eae94bba2730fedf4869921fda79e4d7a8f5d4c
ARG KUBECTX_SHA256_ARM64=1dac2072216689e773325cb7587b858ea7415706ebcf04e23bf80e7e70555340
ARG KUBENS_SHA256_AMD64=326c021c7b35468ed9a187b361198d0f22ae32828139c65eb6670c0d8301cc09
ARG KUBENS_SHA256_ARM64=37058abe82ef20c93b44f3dc8ca2382dbb95d416cec958fbf7b8f79f011be86c

# Latest version of Helm at the moment: https://api.github.com/repos/helm/helm/releases/latest
ARG HELM_VERSION=v4.2.0
ARG HELM_SHA256_AMD64=97dbeb971be4ac4b27e3839976d9564c0fb35c6f3b1da89dd1e292d236af4096
ARG HELM_SHA256_ARM64=1f8de130dfbd04de64978e7b852a7a547be1404956a366608276d2520b678670

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

    # get kubectl
RUN case "${TARGETARCH}" in \
        amd64) KUBECTX_ARCH=x86_64; KUBECTL_SHA256="${KUBECTL_SHA256_AMD64}"; KUBECTX_SHA256="${KUBECTX_SHA256_AMD64}"; KUBENS_SHA256="${KUBENS_SHA256_AMD64}"; HELM_SHA256="${HELM_SHA256_AMD64}" ;; \
        arm64) KUBECTX_ARCH=arm64;  KUBECTL_SHA256="${KUBECTL_SHA256_ARM64}"; KUBECTX_SHA256="${KUBECTX_SHA256_ARM64}"; KUBENS_SHA256="${KUBENS_SHA256_ARM64}"; HELM_SHA256="${HELM_SHA256_ARM64}" ;; \
    esac \
    && curl -fsSLo /usr/local/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" \
    && echo "${KUBECTL_SHA256} */usr/local/bin/kubectl" | sha256sum -c - \
    && chmod +x /usr/local/bin/kubectl \
    # get kubectx
    && curl -fsSLo /tmp/kubectx.tar.gz "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubectx_${KUBECTX_VERSION}_linux_${KUBECTX_ARCH}.tar.gz" \
    && echo "${KUBECTX_SHA256} */tmp/kubectx.tar.gz" | sha256sum -c - \
    && tar -xf /tmp/kubectx.tar.gz -C /usr/local/bin kubectx \
    && chmod +x /usr/local/bin/kubectx \
    # get kubens
    && curl -fsSLo /tmp/kubens.tar.gz "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubens_${KUBECTX_VERSION}_linux_${KUBECTX_ARCH}.tar.gz" \
    && echo "${KUBENS_SHA256} */tmp/kubens.tar.gz" | sha256sum -c - \
    && tar -xf /tmp/kubens.tar.gz -C /usr/local/bin kubens \
    && chmod +x /usr/local/bin/kubens \
    # get helm
    && curl -fsSLo /tmp/helm.tar.gz "https://get.helm.sh/helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" \
    && echo "${HELM_SHA256} */tmp/helm.tar.gz" | sha256sum -c - \
    && tar -xf /tmp/helm.tar.gz -C /usr/local/bin --strip-components=1 "linux-${TARGETARCH}/helm" \
    && chmod +x /usr/local/bin/helm \
    && rm -rf /tmp/*

COPY files/ansiblek8s /

ENTRYPOINT ["docker-entrypoint.sh"]
