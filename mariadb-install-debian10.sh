#!/usr/bin/bash

# This script will install a MariaDB server on Debian 10 and  
# will automate the mysql_secure_installation process too.
# Tune it up to your needs and please, change the password.

# Update the system sources
apt update -y

# Upgrade the system packages
apt upgrade -y

# Install MariaDB
apt install -y mariadb-server mariadb

# Install Expect so the mysql_secure_installation process can be automated
apt install -y expect

# The actual Expect script for a Debian system.
# Remember Debian people make  the root MariaDB user 
# to authenticate using the unix_socket plugin by default rather than with a password.
# Setting a password here is useless. For more info visit the following links:
# https://www.digitalocean.com/community/tutorials/how-to-install-mariadb-on-debian-9
# https://mariadb.com/kb/en/differences-in-mariadb-in-debian-and-ubuntu/
# https://mariadb.com/kb/en/authentication-plugin-unix-socket/
# Crucial to understand this situation on Debian installs: 
# The unix_socket authentication plugin allows the user to use operating system credentials 
# when connecting to MariaDB via the local Unix socket file. This Unix socket file is defined by the socket system variable.
# This basically means the root user from the system is the one able to log in as root into the MariaDB.
# Change the password found below!!!
# Not changing the password found on this script on the internet is a huge security risk.

SECURE_MYSQL=$(expect -c "
set timeout 2
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"Bloody_hell_doN0t\r\"
expect \"Set root password? \[Y/n\]\"
send \"n\r\"
expect \"Remove anonymous users? \[Y/n\]\"
send \"y\r\"
expect \"Disallow root login remotely? \[Y/n\]\"
send \"y\r\"
expect \"Remove test database and access to it? \[Y/n\]\"
send \"y\r\"
expect \"Reload privilege tables now? \[Y/n\]\"
send \"y\r\"
expect eof
")

echo "$SECURE_MYSQL"

# Now MariaDB has been installed you may not need expect anymore.
# Uncomment the line below to remove expect if that is your wish.
# apt remove -y expect

# Sources:
# https://www.digitalocean.com/community/tutorials/how-to-install-mariadb-on-debian-10
# https://www.adminbyaccident.com/freebsd/how-to-freebsd/install-mariadb-freebsd/
