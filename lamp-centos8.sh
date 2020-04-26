#!/usr/bin/bash

# This is an install script for a LAMP stack on CentOS 8.
# Modify it at your convenience.

# Instructions on how to use this script 

# chmod +x SCRIPTNAME.sh

# sudo ./SCRIPTNAME.sh

# Let's update CentOS local repositories on this box.
yum update -y

# Let's upgrade the already installed packages on this box.
yum upgrade -y

# Allow HTTP through the firewall
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload

# Install Expect so the MySQL secure installation process can be automated.
yum install -y expect

# Let's install Apache HTTP
yum install -y httpd

# Enable Apache HTTP service
systemctl enable httpd

# Start Apache HTTP service
systemctl start httpd

# Let's install MariaDB database.
yum install -y mariadb-server mariadb

# Enable MariaDB service
systemctl enable mariadb

# Start up MariaDB
systemctl start mariadb

# Make the hideous 'safe' install for MySQL.Remember Debian people make  the root MariaDB user 
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
send \"\r\"
expect \"Set root password? \[Y/n\]\"
send \"y\r\"
expect \"New password:\"
send \"albert-XP24\r\"
expect \"Re-enter new password:\"
send \"albert-XP24\r\"
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

# Install PHP
yum install -y php php-mysqlnd

# Restart Apache HTTP so it absorves PHP
systemctl restart httpd.service

# Edit the dir.conf file inside the modules-enabled directory for Apache HTTP
# to understand PHP's parlance.
# sed -i 's/DirectoryIndex/DirectoryIndex index.php/' /etc/apache2/mods-enabled/dir.conf

# Restart Apache HTTP with Systemd's systemctl command.
# systemctl reload apache2

# Let's create a directory dedicated to a VirtualHost for one website.
# mkdir /var/www/albertvalbuena.com

# Let's make that directory owned by the Apache HTTP user on Debian
# chown -R httpd:httpd  /var/www/albertvalbuena.com

# Create the VirtualHost configuration file for that website.
#touch /etc/apache2/sites-available/albertvalbuena.com.conf

# Add the VirtualHost configuration into the file
#echo "
#<VirtualHost *:80>
#    ServerName albertvalbuena.com
#    ServerAlias www.albertvalbuena.com 
#    ServerAdmin thewhitereflex@gmail.com
#    DocumentRoot /var/www/albertvalbuena.com
#    ErrorLog ${APACHE_LOG_DIR}/error.log
#    CustomLog ${APACHE_LOG_DIR}/access.log combined
#</VirtualHost>" >> /etc/apache2/sites-available/albertvalbuena.com.conf

# Enable the just created site.
# a2ensite albertvalbuena.com

# Reload Apache HTTP with the new configuration on the new website
# systemctl reload apache2

# Test PHP
# First we create a php file
touch /var/www/html/info.php

# Second we add a simple PHP script so it will display information about the site.
echo "<?php phpinfo(); ?>" >> /var/www/html/info.php

# Once you've visually checked PHP is working manually remove the info.php file.

# Sources:
# https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mysql-php-lamp-stack-on-centos-7
# https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-centos-7-servers
# https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mariadb-php-lamp-stack-on-debian-10
