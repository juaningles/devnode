#! /bin/sh

set -e -x

SUDO=$(which sudo |  head -n 1 | tr -d "\r\n")
$SUDO apt-get update
$SUDO apt-get install -y wget
TRIVY_VERSION=$(curl -s "https://api.github.com/repos/aquasecurity/trivy/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
wget -qO trivy.tar.gz https://github.com/aquasecurity/trivy/releases/latest/download/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz
$SUDO tar xf trivy.tar.gz -C /usr/local/bin trivy
rm -rf trivy.tar.gz
