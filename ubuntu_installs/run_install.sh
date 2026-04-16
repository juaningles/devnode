#!/bin/bash
# Wrapper that runs an installer script with apt cleanup afterward.
# Usage: bash run_install.sh <script_name.sh>
set -eux

SCRIPT="/usr/depot/installers/$1"
test -f "$SCRIPT"

apt-get update
bash "$SCRIPT"
apt-get clean
rm -rf /bd_build
rm -rf /tmp/* /var/tmp/*
rm -rf /var/lib/apt/lists/*
rm -f /etc/ssh/ssh_host_*
