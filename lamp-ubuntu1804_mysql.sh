#!/bin/bash

# This is an install script for a LAMP stack on Ubuntu 18.04 LTS with MySQL instead of MariaDB.

# Instructions on how to use this script 

# chmod +x SCRIPTNAME.sh

# sudo ./SCRIPTNAME.sh

# Update Ubuntu's local repositories on this box.
apt update -y

# Upgrade the already installed packages on this box.
apt upgrade -y

# Enable port 22 for SSH connections on the firewall prior to firing it up
ufw allow 22

# Install Expect to automate the firewall enablement as well as
# the mysql_secure_installation procedure for a later time.
apt install -y expect

# Enable port 22 (for the SSH service) on the UFW firewall.
ENABLE_UFW_22=$(expect -c "
set timeout 2
spawn ufw enable
expect \"Command may disrupt existing ssh connections. Proceed with operation (y|n)?\"
send \"y\r\"
expect eof
")
echo "ENABLE_UFW_22"

# Install Apache HTTP
apt install -y apache2

# Enable the firewall for the Apache HTTP web server
ufw allow in "Apache Full"

# Install MySQL database.
apt install -y mysql-server

# Launch the mysql_secure_installation process

SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Press y|Y for Yes, any other key for No:\"
send \"y\r\"
expect \"Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG:\"
send \"2\r\"
expect \"New password:\"
send \"QB_e-6qUe_vs521\r\"
expect \"Re-enter new password:\"
send \"QB_e-6qUe_vs521\r\"
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

# Install PHP
apt install -y php libapache2-mod-php php-mysql

# Edit the dir.conf file inside the modules-enabled directory for Apache HTTP
# to understand PHP's parlance.
sed -i 's/DirectoryIndex/DirectoryIndex index.php/' /etc/apache2/mods-enabled/dir.conf

# Restart Apache HTTP with Systemd's systemctl command.
systemctl restart apache2

# Create a directory dedicated to a VirtualHost for one website.
mkdir /var/www/albertvalbuena.com

# Make that directory owned by the Apache HTTP user on Debian
chown -R www-data:www-data  /var/www/albertvalbuena.com

# Create a sample index.html page file
touch /var/www/albertvalbuena.com/index.html

# Configure a sample index.html page
echo "
<html>
    <head>
        <title>Welcome to albertvalbuena.com!</title>
    </head>
    <body>
        <h1>Success!  The albertvalbuena.com server block is working!</h1>
    </body>
</html>
" >> /var/www/albertvalbuena.com/index.html

# Create the VirtualHost configuration file for that website.
touch /etc/apache2/sites-available/albertvalbuena.com.conf

# Add the VirtualHost configuration into the file
echo "
<VirtualHost *:80>
    ServerName albertvalbuena.com
    ServerAlias www.albertvalbuena.com 
    ServerAdmin thewhitereflex@gmail.com
    DocumentRoot /var/www/albertvalbuena.com
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>" >> /etc/apache2/sites-available/albertvalbuena.com.conf

# Enable the just created site.
a2ensite albertvalbuena.com.conf

# Disable the default site defined in 000-default.conf
a2dissite 000-default.conf

# Reload Apache HTTP with the new configuration on the new website
systemctl reload apache2

# Test PHP
# First we create a php file
touch /var/www/albertvalbuena.com/info.php

# Second we add a simple PHP script so it will display information about the site.
echo "<?php phpinfo(); ?>" >> /var/www/albertvalbuena.com/info.php

# Uninstall Expect
apt purge -y expect

# Remove Expect dependencies
apt autoremove -y

# Remove the info.php file once you've tested the site.
echo "Remove the info.php file once you've tested the site."

# We are done. Finish announcement.
echo "The LAMP stack has been installed"

# Source:
# https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mysql-php-lamp-stack-ubuntu-18-04
