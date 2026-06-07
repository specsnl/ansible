#!/usr/bin/env bash

set -euo pipefail

printinfo() { printf "\033[1;33m[i]\033[0m %b" "$1\n"; }
printwarn() { printf "\033[1;31m[!]\033[0m %b" "$1\n"; }
printquestion() { printf "\033[1;32m[?]\033[0m %b" "$1\n"; }
printsuccess() { printf "\033[1;32m[✔]\033[0m %b" "$1\n"; }

GITHUB_REPO="ahmetb/kubectx"
DOCKER_ARG_VERSION="KUBECTX_VERSION"
DOCKER_ARG_CHECKSUM_AMD64="KUBENS_SHA256_AMD64"
DOCKER_ARG_CHECKSUM_ARM64="KUBENS_SHA256_ARM64"
CHECKSUM_FILE_NAME="checksums.txt"

NAME=kubens
LATEST_RELEASE=$(curl -fsSL "https://api.github.com/repos/$GITHUB_REPO/releases/latest")
LATEST_VERSION=$(echo "$LATEST_RELEASE" | jq --raw-output '.tag_name')

FILE_NAME_AMD64="${NAME}_${LATEST_VERSION}_linux_x86_64.tar.gz"
FILE_NAME_ARM64="${NAME}_${LATEST_VERSION}_linux_arm64.tar.gz"

LATEST_CHECKSUMS=$(echo "$LATEST_RELEASE" | jq ".assets[] | select(.name == \"$CHECKSUM_FILE_NAME\") | .browser_download_url" | xargs -n 1 curl -fsSL)
LATEST_CHECKSUM_AMD64=$(echo "$LATEST_CHECKSUMS" | grep "${FILE_NAME_AMD64}" | awk '{print $1}')
LATEST_CHECKSUM_ARM64=$(echo "$LATEST_CHECKSUMS" | grep "${FILE_NAME_ARM64}" | awk '{print $1}')

CURRENT_VERSION=$(cat Dockerfile | sed -n "s/^ARG\s*${DOCKER_ARG_VERSION}\s*=\s*\(\S*\).*$/\1/p")
CURRENT_CHECKSUM_AMD64=$(cat Dockerfile | sed -n "s/^ARG\s*${DOCKER_ARG_CHECKSUM_AMD64}\s*=\s*\(\S*\).*/\1/p")
CURRENT_CHECKSUM_ARM64=$(cat Dockerfile | sed -n "s/^ARG\s*${DOCKER_ARG_CHECKSUM_ARM64}\s*=\s*\(\S*\).*/\1/p")

printinfo "Latest $NAME version: $LATEST_VERSION"
printinfo "Latest $NAME checksum (AMD64 sha256sum): $LATEST_CHECKSUM_AMD64"
printinfo "Latest $NAME checksum (ARM64 sha256sum): $LATEST_CHECKSUM_ARM64"
printinfo "Current $NAME version used: $CURRENT_VERSION"
printinfo "Current $NAME checksum used (AMD64): $CURRENT_CHECKSUM_AMD64"
printinfo "Current $NAME checksum used (ARM64): $CURRENT_CHECKSUM_ARM64"

update_message() {
    printwarn "$NAME is NOT up-to-date! Update to:\n"
    echo "ARG $DOCKER_ARG_VERSION=$LATEST_VERSION"
    echo "ARG $DOCKER_ARG_CHECKSUM_AMD64=$LATEST_CHECKSUM_AMD64"
    echo "ARG $DOCKER_ARG_CHECKSUM_ARM64=$LATEST_CHECKSUM_ARM64"
    echo " "
}

echo " "

if [[ ! $CURRENT_VERSION || ! $LATEST_VERSION || $CURRENT_VERSION != $LATEST_VERSION ]]; then
    update_message
    exit 1
fi

if [[ ! $CURRENT_CHECKSUM_AMD64 || ! $LATEST_CHECKSUM_AMD64 || $CURRENT_CHECKSUM_AMD64 != $LATEST_CHECKSUM_AMD64 ]]; then
    update_message
    exit 1
fi

if [[ ! $CURRENT_CHECKSUM_ARM64 || ! $LATEST_CHECKSUM_ARM64 || $CURRENT_CHECKSUM_ARM64 != $LATEST_CHECKSUM_ARM64 ]]; then
    update_message
    exit 1
fi

printsuccess "$NAME is up-to-date!"
echo " "
exit 0
