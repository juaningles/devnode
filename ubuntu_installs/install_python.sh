#! /bin/sh

set -e -x

SUDO=$(which sudo |  head -n 1 | tr -d "\r\n")

$SUDO apt-get update
$SUDO apt-get -y install python3 python3-pip
$SUDO ln -s /usr/bin/python3 /usr/bin/python
