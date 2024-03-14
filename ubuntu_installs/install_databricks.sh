#! /bin/sh

set -e -x

SUDO=$(which sudo |  head -n 1 | tr -d "\r\n")

curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | $SUDO sh
