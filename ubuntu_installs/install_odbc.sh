#! /bin/sh

apt-get update
apt-get -y install python3 python3-pip

RUN apt-get update
apt-get -y install gnupg2
apt-get -y install apt-transport-https
# previous method: curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
curl https://packages.microsoft.com/config/ubuntu/$(awk -F "=" '/^DISTRIB_RELEASE=/ {print $2}' /etc/lsb-release | sed -e 's/22\.10/22.04/')/prod.list > /etc/apt/sources.list.d/mssql-release.list
apt-get update
ACCEPT_EULA=Y apt-get -y install msodbcsql18
