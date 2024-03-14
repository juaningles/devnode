#! /bin/sh

set -e -x

SUDO=$(which sudo |  head -n 1 | tr -d "\r\n")

curl -sL https://aka.ms/InstallAzureCLIDeb | $SUDO bash
