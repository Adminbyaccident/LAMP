#!/usr/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: mediawiki-full-self-signed-deb-pkg.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 12-09-2022
# SET FOR: Test
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: Ubuntu 22.04
#
# PURPOSE: This script installs MediaWiki on top of a LAMP stack using an UNIX socket
#
# REV LIST:
# DATE: 11-09-2022
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

# Install the 'old fashioned' Expect program to automate some manual interventions
# such as enabling the firewall or the mysql_secure_installation bit.
apt install -y expect

# Let's enable the ports for SSH acccess and a web server on the firewall
ufw allow 22
ufw allow 80
ufw allow 443

# Let's enable port 22 (for the SSH service) on the UFW firewall.

ENABLE_UFW_22=$(expect -c "
set timeout 2
spawn ufw enable
expect \"Command may disrupt existing ssh connections. Proceed with operation (y|n)?\"
send \"y\r\"
expect eof
")
echo "ENABLE_UFW_22"

# Install Apache
apt install -y apache2

# Install MySQL
apt install -y mariadb-server mariadb-client

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

# Enable TLS
a2enmod ssl

# Generate a TLS certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt -subj "/C=ES/ST=Barcelona/L=Terrassa/O=Adminbyaccident.com/CN=example.com/emailAddress=thewhitereflex@gmail.com"

# Disable the existing Virtual Host
a2dissite 000-default

# Create the new site's directory
mkdir /var/www/example.com

# Change ownersip of the new site's home directory to the Apache user (www-data in Ubuntu)
chown -R www-data:www-data /var/www/example.com

# Create a new Virtual Host file for the new site
touch /etc/apache2/sites-available/example.com.conf

# Configure the Virtual Host
echo "
<VirtualHost *:80>
	ServerName example.com
	ServerAlias www.example.com 
	Redirect / https://www.example.com/
</VirtualHost>

<VirtualHost *:443>
	ServerName example.com
	ServerAlias www.example.com
	ServerAdmin youremail@example.com
	DocumentRoot /var/www/your_domain_or_ip
	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined
	<FilesMatch \".php$\">
	SetHandler \"proxy:unix:/var/run/php/php8.1-fpm.sock\|fcgi://localhost/\"
</FilesMatch>

SSLEngine on
SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt
SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key
</VirtualHost>" >> /etc/apache2/sites-available/example.com.conf

# Enable the new site
a2ensite example.com

# Enable the proxy module
a2enmod proxy

# Enable the proxy_fcgi module
a2enmod proxy_fcgi setenvif

# Restart Apache2
systemctl reload apache2

# Tune PHP for MediaWiki
sed -i -e '/upload_max_filesize/s/upload_max_filesize = 2M/upload_max_filesize = 64M/'g /etc/php/8.1/fpm/php.ini
sed -i -e 'memory_limit/s/memory_limit = 128M/memory_limit = 256M/'g /etc/php/8.1/fpm/php.ini

# Reload the PHP service to get these changes to be applied
systemctl reload php8.1-fpm.service

# Install pwgen in order to generate random values for DB_NAME, DB_USER_NAME and NEW_DB_PASSWORD when building a new DB for MediaWiki
apt install -y pwgen

# Create the database for MediaWiki

NEW_DB_NAME=$(pwgen 8 --secure --numerals --capitalize) && export NEW_DB_NAME && echo $NEW_DB_NAME >> /root/new_db_name.txt

NEW_DB_USER_NAME=$(pwgen 10 --secure --numerals --capitalize) && export NEW_DB_USER_NAME && echo $NEW_DB_USER_NAME >> /root/new_db_user_name.txt

NEW_DB_PASSWORD=$(pwgen 32 --secure --numerals --capitalize) && export NEW_DB_PASSWORD && echo $NEW_DB_PASSWORD >> /root/newdb_pwd.txt

NEW_DATABASE=$(expect -c "
set timeout 10
spawn mysql -u root -p
expect \"Enter password:\"
send \"\r\"
expect \"MariaDB \[(none)\]>\"
send \"CREATE DATABASE $NEW_DB_NAME;\r\"
expect \"MariaDB \[(none)\]>\"
send \"CREATE USER '$NEW_DB_USER_NAME'@'localhost' IDENTIFIED BY '$NEW_DB_PASSWORD';\r\"
expect \"MariaDB \[(none)\]>\"
send \"GRANT ALL PRIVILEGES ON $NEW_DB_NAME.* TO '$NEW_DB_USER_NAME'@'localhost';\r\"
expect \"MariaDB \[(none)\]>\"
send \"FLUSH PRIVILEGES;\r\"
expect \"MariaDB \[(none)\]>\"
send \"exit\r\"
expect eof
")

echo "$NEW_DATABASE"

# No one but root can read these files. Read only permissions.
chmod 400 /root/new_db_name.txt
chmod 400 /root/new_db_user_name.txt
chmod 400 /root/newdb_pwd.txt

# Perform the MediaWiki installation (based on Ubuntu packages)
apt install -y mediawiki

# Display the new database, username and password generated on MySQL
echo "Your NEW_DB_NAME is written on this file /root/new_db_name.txt"
echo "Your NEW_DB_USER_NAME is written on this file /root/new_db_user_name.txt"
echo "Your NEW_DB_PASSWORD is written on this file /root/newdb_pwd.txt"

# Final message
echo "MediaWiki has been installed on this server. Please visit the URL of this server http://example.com/mediawiki/ with your browser and finish the install there."

## References in the following URLS:

## https://www.digitalocean.com/community/tutorials/how-to-configure-apache-http-with-mpm-event-and-php-fpm-on-freebsd-12-0
## https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/
## https://cwiki.apache.org/confluence/display/HTTPD/PHP-FPM
