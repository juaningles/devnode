#! /bin/bash --debug

set -e -x

SUDO=$(which sudo |  head -n 1 | tr -d "\r\n")
$SUDO apt-get update
$SUDO apt-get -y install python3 python3-pip

$SUDO apt-get -y install gnupg2
$SUDO apt-get -y install apt-transport-https
# previous method: curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -

##curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
##curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list

curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | $SUDO gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
curl https://packages.microsoft.com/keys/microsoft.asc |  $SUDO tee /etc/apt/trusted.gpg.d/microsoft.asc
curl https://packages.microsoft.com/config/ubuntu/$(awk -F "=" '/^DISTRIB_RELEASE=/ {print $2}' /etc/lsb-release | $SUDO sed -e 's/22\.10/22.04/')/prod.list > /etc/apt/sources.list.d/mssql-release.list

$SUDO apt-get update
export ACCEPT_EULA=Y
$SUDO apt-get -y install msodbcsql18

# optional: for bcp and sqlcmd
$SUDO apt-get install -y mssql-tools18
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
source ~/.bashrc
# optional: for unixODBC development headers
$SUDO  apt-get install -y unixodbc-dev
