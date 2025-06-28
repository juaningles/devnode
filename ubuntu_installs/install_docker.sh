#!/bin/bash
set -e -x

SUDO=$(which sudo |  head -n 1 | tr -d "\r\n")

$SUDO apt update
$SUDO apt -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
$SUDO mkdir -p /etc/apt/keyrings
$SUDO curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO  gpg --dearmor -o /etc/apt/keyrings/docker.gpg
$SUDO curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO  gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg
$SUDO echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | $SUDO  tee /etc/apt/sources.list.d/docker.list > /dev/null
$SUDO apt update
$SUDO apt install docker-ce docker-ce-cli containerd.io -y
