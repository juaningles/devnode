#! /bin/sh

set -e -x

SUDO=$(which sudo |  head -n 1 | tr -d "\r\n")

$SUDO apt-get update
$SUDO apt-get -y install vim git make curl jq tmux unzip tzdata bash-completion
