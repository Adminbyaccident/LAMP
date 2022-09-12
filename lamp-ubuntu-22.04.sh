#!/usr/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: lamp-ubuntu-22.04.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 12-09-2022
# SET FOR: Test
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: Ubuntu 22.04
#
# PURPOSE: This script installs a LAMP stack (Apache 2.4, MariaDB 10.6 and PHP 8.1)
#
# REV LIST:
# DATE: 12-09-2022
# BY: ALBERT VALBUENA
# MODIFICATION: 12-09-2022
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!

##########################################################
################ BEGINNING OF MAIN #######################
##########################################################

# Update packages 
apt update && apt upgrade -y

# Enable port 22 for SSH connections on the firewall prior to firing it up
ufw allow 22

# Install Expect so the MySQL secure installation process can be automated.
apt install -y expect

# Let's enable port 22 (for the SSH service) on the UFW firewall.

ENABLE_UFW_22=$(expect -c "
set timeout 2
spawn ufw enable
expect \"Command may disrupt existing ssh connections. Proceed with operation (y|n)?\"
send \"y\r\"
expect eof
")
echo "ENABLE_UFW_22"

# Let's enable the ports for a web server on the firewall
ufw allow 80
ufw allow 443

# Install Apache
apt install -y apache2

# Install MySQL
apt install -y mariadb-server mariadb-client

# Install the 'old fashioned' Expect program to automate the mysql_secure_installation part
apt install -y expect

# Perform the mysql_secure_installation script

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

# Install the PHP-FPM package
apt install -y php-fpm

# Install the FastCGI module for Apache2
apt install -y libapache2-mod-fcgid

# Enable the FastCGI module
a2enmod fcgid

# Enable the PHP-FPM module
a2enconf php8.1-fpm

# Enable the proxy module
a2enmod proxy

# Enable the proxy_fcgi module
a2enmod proxy_fcgi setenvif

# Enable HTTP/2
a2enmod http2

# Restart Apache2
systemctl reload apache2

# Final message
echo "A LAMP stack system has been deployed."

# EOF
