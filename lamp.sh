#!/usr/bin/bash

# This is an install script for a LAMP stack on Debian 10.
# Modify it at your convenience.

# Let's update Debian local repositories on this box.
apt update -y

# Let's upgrade the already installed packages on this box.
apt upgrade -y

# Install Expect so the MySQL secure installation process can be automated.
apt install -y expect

# Let's install the firewall software UFW (Uncomplicated Firewall).
apt install -y ufw

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
ufw allow in "WWW Full"

# Let's activate the firewall.
ufw enable

# Let's install Apache HTTP
apt install -y apache2

# Let's install MariaDB database.
apt install -y mariadb-server

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

# Install PHP
apt install -y php libapache2-mod-php php-mysql

# Edit the dir.conf file inside the modules-enabled directory for Apache HTTP
# to understand PHP's parlance.
sed -i 's/DirectoryIndex/DirectoryIndex index.php/' /etc/apache2/mods-enabled/dir.conf

# Restart Apache HTTP with Systemd's systemctl command.
systemctl reload apache2

# Let's create a directory dedicated to a VirtualHost for one website.
mkdir /var/www/your_domain

# Let's make that directory owned by the Apache HTTP user on Debian
chown -R www-data:www-data  /var/www/your_domain

# Create the VirtualHost configuration file for that website.
touch /etc/apache2/sites-available/your_domain.conf

# Add the VirtualHost configuration into the file
echo "
<VirtualHost *:80>
    ServerName your_domain
    ServerAlias www.your_domain.com 
    ServerAdmin your_email@email.com
    DocumentRoot /var/www/your_domain
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>" >> /etc/apache2/sites-available/your_domain.conf

# Enable the just created site.
a2ensite your_domain

# Reload Apache HTTP with the new configuration on the new website
systemctl reload apache2

# Test PHP
# First we create a php file
touch /var/www/your_domain/info.php

# Second we add a simple PHP script so it will display information about the site.
echo "<?php phpinfo(); ?>" >> /var/www/your_domain/info.php


# Sources:
# https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mariadb-php-lamp-stack-on-debian-10
# https://www.adminbyaccident.com/gnu-linux/lamp-stack-debian/
