#! /bin/sh

set -e -x

SUDO=$(which sudo |  head -n 1 | tr -d "\r\n")

$SUDO apt-get update
$SUDO apt-get -y install dnsutils iputils-ping nmap netcat-openbsd
