#!/bin/bash

# This is an install script for a LAMP stack on Ubuntu 18.04 LTS.
# It will modify the LAMP stack to use the MPM Event module instead of the default prefork
# It will also make use of the PHP-FPM processor for PHP
# More info on my FreeBSD guides:
# https://www.digitalocean.com/community/tutorials/how-to-configure-apache-http-with-mpm-event-and-php-fpm-on-freebsd-12-0
# https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/

# Instructions on how to use this script 

# chmod +x SCRIPTNAME.sh

# sudo ./SCRIPTNAME.sh

# Update Ubuntu's local repositories on this box.
apt update -y

# Upgrade the already installed packages on this box.
apt upgrade -y

# Stop the Apache2 service
systemctl stop apache2

# Disable the PHP module for Apache2
a2dismod php7.2

# Disable the MPM prefork module
a2dismod mpm_prefork

# Enable the MPM Event module
a2enmod mpm_event

# Install the PHP-FPM package
apt install -y php-fpm

# Install the FastCGI module for Apache2
apt install -y libapache2-mod-fcgid

# Enable the FastCGI module
a2enmod fcgid

# Enable the PHP-FPM module
a2enconf php7.2-fpm

# Remove the existing Virtual Host
rm /etc/apache2/sites-available/albertvalbuena.com.conf 

# Create a new Virtual Host file
touch /etc/apache2/sites-available/albertvalbuena.com.conf

# Configure the Virtual Host
echo "
<VirtualHost *:80>
    ServerName albertvalbuena.com
    ServerAlias www.albertvalbuena.com 
    ServerAdmin thewhitereflex@gmail.com
    DocumentRoot /var/www/albertvalbuena.com
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
	<FilesMatch ".php$">
	SetHandler "proxy:unix:/var/run/php/php7.2-fpm.sock\|fcgi://localhost/"
	</FilesMatch>
</VirtualHost>" >> /etc/apache2/sites-available/albertvalbuena.com.conf

# Enable the proxy module
a2enmod proxy

# Enable the proxy_fcgi module
a2enmod proxy_fcgi

# Restart Apache2
systemctl restart apache2

# Sources:
# https://www.digitalocean.com/community/tutorials/how-to-configure-apache-http-with-mpm-event-and-php-fpm-on-freebsd-12-0
# https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/
