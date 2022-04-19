#!/usr/bin/bash
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: lamp-centos8.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 18-12-2020
# SET FOR: Production
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: CentOS 8 / RHEL 8
#
# PURPOSE: This is an install script for a full LAMP stack on CentOS 8
#
# REV LIST:
# DATE: 18-12-2020
# BY: ALBERT VALBUENA
# MODIFICATION: 12-12-2021
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!

##########################################################
################ BEGINNING OF MAIN #######################
##########################################################

# Let's update CentOS local repositories on this box.
dnf update -y

# Allow HTTP through the firewall
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload

# Let's install Apache HTTP
dnf install -y httpd

# Enable Apache HTTP service
systemctl enable httpd

# Start Apache HTTP service
systemctl start httpd

# Let's install MariaDB database.
dnf -y module enable mariadb:10.5
dnf install -y mariadb-server mariadb

# Enable MariaDB service
systemctl enable mariadb

# Start up MariaDB
systemctl start mariadb

# Uncomment the line below if you prefer to have a password protected access to MariaDB
# instead of just using privileges inherited from using the system's root account.
# Do also uncomment the second expect script and comment out the first one.
# More details here: https://mariadb.com/kb/en/authentication-plugin-unix-socket/

#dnf install -y pwgen
#DB_ROOT_PASSWORD=$(pwgen 32 --secure --numerals --capitalize) && export DB_ROOT_PASSWORD && echo $DB_ROOT_PASSWORD >> /root/db_root_pwd.txt

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

#SECURE_MARIADB=$(expect -c "
#set timeout 2
#spawn mysql_secure_installation
#expect \"Enter current password for root (enter for none):\"
#send \"Bloody_hell_doN0t\r\"
#expect \"Switch to unix_socket authentication\"
#send \"y\r\"
#expect \"Change the root password?\"
#send \"y\r\"
#expect \"New password\r\"
#send \"$DB_ROOT_PASSWORD\r\"
#expect \"Re-enter new password:\r\"
#send \"$DB_ROOT_PASSWORD\r\"
#expect \"Remove anonymous users?\"
#send \"y\r\"
#expect \"Disallow root login remotely?\"
#send \"y\r\"
#expect \"Remove test database and access to it?\"
#send \"y\r\"
#expect \"Reload privilege tables now?\"
#send \"y\r\"
#expect eof
#")

#echo "$SECURE_MARIADB"

# No one but root can read this file. Read only permission.
chmod 400 /root/db_root_pwd.txt

# Install PHP
dnf -y module enable php:7.4
dnf install -y php php-mysqlnd

# Restart Apache HTTP so it absorves PHP
systemctl restart httpd.service

# Test PHP
# First we create a php file
touch /var/www/html/info.php

# Second we add a simple PHP script so it will display information about the site.
echo "<?php phpinfo(); ?>" >> /var/www/html/info.php

echo "Once you've visually checked PHP is working manually remove the info.php file placed in /var/www/html/info.php"

# Uncomment the line below to display the location of the generated root password for MariaDB
# if you've uncommented the use of pwgen in the MariaDB install
# echo "Your DB_ROOT_PASSWORD is written on this file /root/db_root_pwd.txt"

# Sources:
# https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mysql-php-lamp-stack-on-centos-7
# https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-centos-7-servers
# https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mariadb-php-lamp-stack-on-debian-10
