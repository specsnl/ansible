# syntax=docker/dockerfile:1
# check=error=true

# Latest version: https://github.com/astral-sh/uv/releases
FROM ghcr.io/astral-sh/uv:0.12.19 AS uv

# Latest version: https://hub.docker.com/_/python/tags
FROM python:3.14.7-alpine3.24 AS ansible

ENV HOME=/home

WORKDIR /workspace

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
    && UV_PROJECT_ENVIRONMENT=/opt/venv uv sync --frozen --no-dev \
    && rm pyproject.toml uv.lock

COPY files/ansible /

ENV PATH="/opt/venv/bin:$PATH"

FROM ansible AS k8s

ARG TARGETARCH

# Latest version of Kubectl at the moment: https://dl.k8s.io/release/stable.txt
ARG KUBECTL_VERSION=v1.37.1
ARG KUBECTL_SHA256_AMD64=65691ff77eb6fa44c908b77a1082c9f092c3b9733b5cefabec0d1104890e21a8
ARG KUBECTL_SHA256_ARM64=ff749f4b78d9c4f1ec87307df9b50119ed819e2094aa9810cb9acffc3286c8c7

# Latest version of kubectx/kubens at the moment: https://api.github.com/repos/ahmetb/kubectx/releases/latest
ARG KUBECTX_VERSION=v0.11.0
ARG KUBECTX_SHA256_AMD64=08e031c54fbffb3f100e904e4eae94bba2730fedf4869921fda79e4d7a8f5d4c
ARG KUBECTX_SHA256_ARM64=1dac2072216689e773325cb7587b858ea7415706ebcf04e23bf80e7e70555340
ARG KUBENS_SHA256_AMD64=326c021c7b35468ed9a187b361198d0f22ae32828139c65eb6670c0d8301cc09
ARG KUBENS_SHA256_ARM64=37058abe82ef20c93b44f3dc8ca2382dbb95d416cec958fbf7b8f79f011be86c

# Latest version of Helm at the moment: https://api.github.com/repos/helm/helm/releases/latest
ARG HELM_VERSION=v4.2.4
ARG HELM_SHA256_AMD64=c306b46f719b0a4da32d0f78ee21bf90ce8d602f15b22ab753f0674d1670a7f3
ARG HELM_SHA256_ARM64=564de2191b881e9f71b5606b25345821ea1682f06ab90499d3ab22b530176da1

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

    # get kubectl
RUN case "${TARGETARCH}" in \
        amd64) KUBECTX_ARCH=x86_64; KUBECTL_SHA256="${KUBECTL_SHA256_AMD64}"; KUBECTX_SHA256="${KUBECTX_SHA256_AMD64}"; KUBENS_SHA256="${KUBENS_SHA256_AMD64}"; HELM_SHA256="${HELM_SHA256_AMD64}" ;; \
        arm64) KUBECTX_ARCH=arm64;  KUBECTL_SHA256="${KUBECTL_SHA256_ARM64}"; KUBECTX_SHA256="${KUBECTX_SHA256_ARM64}"; KUBENS_SHA256="${KUBENS_SHA256_ARM64}"; HELM_SHA256="${HELM_SHA256_ARM64}" ;; \
    esac \
    && curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" \
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
