# Latest version of Debian image: https://hub.docker.com/_/debian
ARG DEBIAN_VERSION=13.5-slim

FROM debian:${DEBIAN_VERSION} AS builder

ARG UNIQUE_ID_FOR_CACHEFROM=builder

WORKDIR /ansible

RUN apt-get update \
    && apt-get install --assume-yes --no-install-recommends \
        build-essential \
        gcc \
        python3 \
        python3-venv \
    && python3 -m venv /opt/venv \
    && apt-get autoremove --assume-yes \
    && apt-get clean --assume-yes \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

ENV PATH="/opt/venv/bin:$PATH"

RUN python3 -m pip install --upgrade --no-cache-dir --progress-bar off \
        pip \
        wheel \
        setuptools

COPY requirements.txt /ansible/requirements.txt

RUN python3 -m pip install --no-cache-dir --progress-bar off --requirement /ansible/requirements.txt

FROM debian:${DEBIAN_VERSION} AS ansible

ARG UNIQUE_ID_FOR_CACHEFROM=ansible

ENV HOME=/home

WORKDIR /ansible

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN chmod 777 -R "$HOME" \
    && apt-get update \
    && apt-get install --assume-yes --no-install-recommends \
        ca-certificates \
        curl \
        openssl \
        git \
        openssh-client \
        python3 \
        jq \
        gnupg \
        pass \
        rsync \
        sshpass \
        sudo \
        unzip \
        # deps for docker-ce-cli
        lsb-release \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor - > /usr/share/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker-ce.list \
    && apt-get update \
    && apt-get install --assume-yes --no-install-recommends docker-ce-cli \
    # Ansible requires the running user to have a passwd entry
    && for i in $(seq 500 1999); do echo "user:x:$i:$i::/home:/sbin/nologin"; done >> /etc/passwd \
    && apt-get purge --assume-yes \
        lsb-release \
    && apt-get autoremove --assume-yes \
    && apt-get clean --assume-yes \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

COPY files/ansible /
COPY --from=builder /opt/venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

FROM ansible AS k8s

ARG UNIQUE_ID_FOR_CACHEFROM=ansiblek8s

# Latest version of Kubectl at the moment: https://storage.googleapis.com/kubernetes-release/release/stable.txt
ARG KUBECTL_VERSION=v1.31.0
ARG KUBECTL_SHA256=7c27adc64a84d1c0cc3dcf7bf4b6e916cc00f3f576a2dbac51b318d926032437
# Latest version of kubectx/kubens at the moment: https://api.github.com/repos/ahmetb/kubectx/releases/latest
ARG KUBECTX_VERSION=v0.11.0
ARG KUBECTX_SHA256=08e031c54fbffb3f100e904e4eae94bba2730fedf4869921fda79e4d7a8f5d4c
ARG KUBENS_SHA256=326c021c7b35468ed9a187b361198d0f22ae32828139c65eb6670c0d8301cc09
# Latest version of Helm at the moment: https://api.github.com/repos/helm/helm/releases/latest
ARG HELM_VERSION=v4.2.0
ARG HELM_SHA256=97dbeb971be4ac4b27e3839976d9564c0fb35c6f3b1da89dd1e292d236af4096

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

    # get kubectl
RUN curl -fsSLo /usr/local/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl" \
    && echo "$KUBECTL_SHA256 */usr/local/bin/kubectl" | sha256sum -c - \
    && chmod +x /usr/local/bin/kubectl \
    # get kubectx
    && curl -fsSLo /tmp/kubectx.tar.gz "https://github.com/ahmetb/kubectx/releases/download/$KUBECTX_VERSION/kubectx_${KUBECTX_VERSION}_linux_x86_64.tar.gz" \
    && echo "$KUBECTX_SHA256 */tmp/kubectx.tar.gz" | sha256sum -c - \
    && tar -xf /tmp/kubectx.tar.gz -C /usr/local/bin kubectx \
    && chmod +x /usr/local/bin/kubectx \
    # get kubens
    && curl -fsSLo /tmp/kubens.tar.gz "https://github.com/ahmetb/kubectx/releases/download/$KUBECTX_VERSION/kubens_${KUBECTX_VERSION}_linux_x86_64.tar.gz" \
    && echo "$KUBENS_SHA256 */tmp/kubens.tar.gz" | sha256sum -c - \
    && tar -xf /tmp/kubens.tar.gz -C /usr/local/bin kubens \
    && chmod +x /usr/local/bin/kubens \
    # get helm
    && curl -fsSLo /tmp/helm.tar.gz "https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz" \
    && echo "$HELM_SHA256 */tmp/helm.tar.gz" | sha256sum -c - \
    && tar -xf /tmp/helm.tar.gz -C /usr/local/bin --strip-components=1 linux-amd64/helm \
    && chmod +x /usr/local/bin/helm \
    && rm -rf /tmp/*

COPY files/ansiblek8s /

ENTRYPOINT ["docker-entrypoint.sh"]
