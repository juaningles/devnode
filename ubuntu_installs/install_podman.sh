#! /bin/sh
SUDO=$(which sudo |  head -n 1 | tr -d "\r\n")

apt-get update
apt-get -y install podman podman-docker


# might be needed on non container install:

# $SUDO usermod --add-subuids 10000-75535 $(whoami)
# $SUDO usermod --add-subgids 10000-75535 $(whoami)
# $SUDO echo "$(whoami):10000:65536" >> /etc/subuid
# $SUDO echo "$(whoami):10000:65536" >> /etc/subgid
