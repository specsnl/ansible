ARG DEBIAN_VERSION=13.2-slim

FROM debian:${DEBIAN_VERSION} AS builder

ARG UNIQUE_ID_FOR_CACHEFROM=builder

WORKDIR /ansible

RUN apt-get update \
    && apt-get install --assume-yes --no-install-recommends \
        build-essential \
        gcc \
        python3-full \
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

# Everything above this line is the same as the main Dockerfile

RUN python3 -m pip install --no-cache-dir --progress-bar off \
        # for better Ansible password_hash() support
        passlib \
        bcrypt \
        # openshift is a requirement of the k8s Ansible module
        openshift \
        # needed for Ansible k8s module's validate support
        kubernetes-validate \
        # needed for Ansible dns lookup support
        dnspython \
        # needed for Ansible ipaddr functions
        netaddr \
        # needed for Ansible hashi_vault plugin support
        hvac \
        # needed for Ansible docker \
        docker \
        # misc
        ansible-lint \
        yamllint \
        molecule[docker] \
        # ...
        ansible

CMD ["python3", "-m", "pip", "freeze", "--all"]
