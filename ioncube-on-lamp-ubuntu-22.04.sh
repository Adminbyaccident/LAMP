#!/usr/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: ioncube-on-lamp-ubuntu-22.04.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 05-08-2023
# SET FOR: Test
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: Ubuntu 22.04
#
# PURPOSE: This script installs ionCUBE on a LAMP stack (Apache 2.4, MySQL 8 and PHP 8.1)
# For more information: https://www.ioncube.com/loaders.php
#
# REV LIST:
# DATE: 05-08-2023
# BY: ALBERT VALBUENA
# MODIFICATION: 05-08-2023
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
apt install -y mysql-server mysql-client

# Install pwgen to automatically generate passwords
apt install -y pwgen

# Define the DB root password and export it as a variable to make it available for the expect script. Plus write it on the root directory.
DB_ROOT_PASSWORD=$(pwgen 32 --secure --numerals --capitalize) && export DB_ROOT_PASSWORD && echo $DB_ROOT_PASSWORD >> /root/db_root_pwd.txt

# Install the 'old fashioned' Expect program to automate the mysql_secure_installation part
apt install -y expect

SECURE_MYSQL=$(expect -c "
set timeout 10
set DB_ROOT_PASSWORD "$DB_ROOT_PASSWORD"
spawn mysql_secure_installation
expect \"Press y|Y for Yes, any other key for No:\"
send \"y\r\"
expect \"Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG:\"
send \"0\r\"
expect \"New password:\"
send \"$DB_ROOT_PASSWORD\r\"
expect \"Re-enter new password:\"
send \"$DB_ROOT_PASSWORD\r\"
expect \"Do you wish to continue with the password provided?(Press y|Y for Yes, any other key for No) :\"
send \"Y\r\"
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

echo "$SECURE_MYSQL"

# No one but root can read this file. Read only permission.
chmod 400 /root/db_root_pwd.txt

# Install the PHP-FPM package
apt install -y php8.1 php8.1-fpm

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

# Download ioncube loaders
wget -O /tmp/ioncube_loaders_lin_x86-64.tar.gz https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz

# Unpack ioncube loaders
tar -zxf /tmp/ioncube_loaders_lin_x86-64.tar.gz -C /root

# Move ioncube loaders into /usr/local
mv /root/ioncube /usr/local

# Configure PHP 8.1 to use ioncube loaders
echo 'zend_extension = /usr/local/ioncube/ioncube_loader_lin_8.1.so' >> /etc/php/8.1/cli/php.ini
echo 'zend_extension = /usr/local/ioncube/ioncube_loader_lin_8.1.so' >> /etc/php/8.1/fpm/php.ini

# Reload PHP-FPM to recognise the PHP configuration change in php.ini
systemctl reload php8.1-fpm.service

# Final message
echo "A LAMP stack system has been deployed."

# Display the location of the generated root password for MySQL
echo "Your DB_ROOT_PASSWORD is written on this file /root/db_root_pwd.txt"

# Ioncube has been installed
echo "Ioncube Loaders have been installed on this LAMP server."

# EOF
