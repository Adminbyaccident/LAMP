#!/bin/bash
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: lamp-ubuntu1804_event-php_fpm.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 31-05-2020
# SET FOR: Production
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: Ubuntu 18.04
#
# PURPOSE: This script configures the LAMP stack on an Ubuntu 18.04 system to use the Event MPM module on Apache HTTP and PHP-FPM
#
# REV LIST:
# DATE: 14-12-2021
# BY: ALBERT VALBUENA
# MODIFICATION: 14-12-2021
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!

##########################################################
################ BEGINNING OF MAIN #######################
##########################################################

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
rm /etc/apache2/sites-available/example.com.conf 

# Create a new Virtual Host file
touch /etc/apache2/sites-available/example.com.conf

# Configure the Virtual Host
echo "
<VirtualHost *:80>
    ServerName example.com
    ServerAlias www.example.com 
    ServerAdmin youremail@gmail.com
    DocumentRoot /var/www/example.com
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
	<FilesMatch ".php$">
	SetHandler "proxy:unix:/var/run/php/php7.2-fpm.sock\|fcgi://localhost/"
	</FilesMatch>
</VirtualHost>" >> /etc/apache2/sites-available/example.com.conf

# Enable the proxy module
a2enmod proxy

# Enable the proxy_fcgi module
a2enmod proxy_fcgi

# Restart Apache2
systemctl restart apache2

# Sources:
# https://www.digitalocean.com/community/tutorials/how-to-configure-apache-http-with-mpm-event-and-php-fpm-on-freebsd-12-0
# https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/
