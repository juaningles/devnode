#! /bin/bash --debug

set -e -x

SUDO=$(which sudo |  head -n 1 | tr -d "\r\n")
$SUDO apt-get update
$SUDO apt-get -y install python3 python3-pip

# $SUDO apt-get -y install gnupg2
# $SUDO apt-get -y install apt-transport-https

# install the Microsoft ODBC driver for SQL Server
# instructions as of 01/03/2025
# https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver17&tabs=ubuntu18-install%2Cubuntu17-install%2Cdebian8-install%2Credhat7-13-install%2Crhel7-offline
curl -sSL -O https://packages.microsoft.com/config/ubuntu/$(grep VERSION_ID /etc/os-release | cut -d '"' -f 2 | sed -e 's/22\.10/22.04/' | sed -e 's/24\.../22.04/' | sed -e 's/26\.../25.10/')/packages-microsoft-prod.deb
$SUDO dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb


$SUDO apt-get update
export ACCEPT_EULA=Y
# $SUDO apt-get -y install msodbcsql18

# optional: for bcp and sqlcmd
$SUDO apt-get install -y mssql-tools18
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
source ~/.bashrc
# optional: for unixODBC development headers
$SUDO  apt-get install -y unixodbc-dev
