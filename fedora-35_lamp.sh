#!/usr/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: fedora-35_lamp.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 16-04-2022
# SET FOR: Production
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: Fedora 35
#
# PURPOSE: This script installs a full LAMP stack with Apache HTTP configured with MPM as Event + MariaDB 10.7 + PHP-FPM configured to read from the TCP socket
#
# REV LIST:
# DATE: 16-04-2022
# BY: ALBERT VALBUENA
# MODIFICATION: 16-04-2022
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!

##########################################################
################ BEGINNING OF MAIN #######################
##########################################################

# Update the OS
dnf update -y

# Install Apache HTTP
dnf install httpd -y

# Enable and start up the Apache HTTP service
systemctl enable httpd --now

# Enable the HTTP and HTTPS services at the firewall
firewall-cmd --add-service=http --add-service=https --permanent
firewall-cmd --reload

# Enable MariaDB 10.7
dnf -y module enable mariadb:10.7

# Install MariaDB 10.7 client and server
dnf -y install mariadb mariadb-server

# Enable and start up MariaDB 10.7
systemctl enable mariadb --now

# Enable PHP 8.1 with the remi repository
dnf -y install http://rpms.remirepo.net/fedora/remi-release-35.rpm

# Reset the local repository for PHP
dnf -y module reset php

# Eanble the PHP 8.1 repository for local use
dnf -y module enable php:remi-8.1

# Install PHP 8.1
dnf -y module install php:remi-8.1

# Enable PHP-FPM
systemctl enable php-fpm --now

# Install Expect so the MySQL secure installation process can be automated.
dnf install -y expect

SECURE_MARIADB=$(expect -c "
set timeout 2
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"Bloody_hell_doN0t\r\"
expect \"Switch to unix_socket authentication\"
send \"n\r\"
expect \"Change the root password?\"
send \"n\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")

echo "$SECURE_MARIADB"

# Edit the ServerName directive
sed -i -e '/ServerName/s/#ServerName/ServerName/' /etc/httpd/conf/httpd.conf

echo "The LAMP stack on Fedora 35 has been installed. No hardening has been made on this script."
