#!/usr/bin/bash
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: self-full-lamp-wordpress-centos9.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 11-01-2023
# SET FOR: Test
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: CentOS Stream 9 / RHEL 9
#
# PURPOSE: This is an install script for a full LAMP stack on CentOS Stream 9
#
# REV LIST:
# DATE: 
# BY: ALBERT VALBUENA
# MODIFICATION: 
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

# Install EPEL repository
dnf install -y epel-release
dnf update -y

# Install firewalld
dnf install -y firewalld
systemctl enable firewalld
systemctl start firewalld

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

# Enable SELinux to allow the web server to connect to the network
setsebool -P httpd_can_network_connect 1

# Let's install MariaDB database.
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
dnf install -y php php-mysqlnd

# Restart Apache HTTP so it absorves PHP
systemctl restart httpd.service

# Test PHP
# First we create a php file
touch /var/www/html/info.php

# The WordPress adaptation for the LAMP scrip starts here

# Install the TLS module for Apache HTTP
dnf install -y mod_ssl

# Apply HTTP redirection to HTTPS

echo '
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
' >> /etc/httpd/conf/httpd.conf

# Installing missing dependencies
dnf install -y httpd-tools php php-cli php-json php-gd php-mbstring php-pdo php-xml php-mysqlnd php-pecl-zip wget php-pecl-imagick php-intl

# Avoid PHP's information (version, etc) being disclosed
sed -i -e '/expose_php/s/expose_php = On/expose_php = Off/' /etc/php.ini

# Enable Security Headers
echo '
<IfModule mod_headers.c>
    Header set Content-Security-Policy "upgrade-insecure-requests;"
    Header set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always edit Set-Cookie (.*) "$1; HttpOnly; Secure"
    Header set X-Content-Type-Options "nosniff"
    Header set X-XSS-Protection "1; mode=block"
    Header set Referrer-Policy "strict-origin"
    Header set X-Frame-Options: "deny"
    SetEnv modHeadersAvailable true
    Header always set Permissions-Policy "geolocation=(),midi=(),sync-xhr=(),microphone=(),camera=(),magnetometer=(),gyroscope=(),fullscreen=(self),payment=()"
</IfModule>' >>  /etc/httpd/conf.d/headers.conf

# Because Wordpress and plugins will make use of an .htaccess file, let's enable it.
sed -i -e "156s/AllowOverride None/AllowOverride All/" /etc/httpd/conf/httpd.conf

# Create the DB for WordPress
# Create the database and user. Mind this is MariaDB
echo 'Creating a database for WordPress'

dnf install -y pwgen

touch /root/new_db_name.txt
touch /root/new_db_user_name.txt
touch /root/newdb_pwd.txt

echo "Generating new database, username and passoword for the WordPress install"

NEW_DB_NAME=$(pwgen 8 --secure --numerals --capitalize) && export NEW_DB_NAME && echo $NEW_DB_NAME >> /root/new_db_name.txt

NEW_DB_USER_NAME=$(pwgen 10 --secure --numerals --capitalize) && export NEW_DB_USER_NAME && echo $NEW_DB_USER_NAME >> /root/new_db_user_name.txt

NEW_DB_PASSWORD=$(pwgen 32 --secure --numerals --capitalize) && export NEW_DB_PASSWORD && echo $NEW_DB_PASSWORD >> /root/newdb_pwd.txt

NEW_DATABASE=$(expect -c "
set timeout 10
spawn mysql -u root -p
expect \"Enter password:\"
send \"\r\"
expect \"root@localhost \[(none)\]>\"
send \"CREATE DATABASE $NEW_DB_NAME;\r\"
expect \"root@localhost \[(none)\]>\"
send \"CREATE USER '$NEW_DB_USER_NAME'@'localhost' IDENTIFIED BY '$NEW_DB_PASSWORD';\r\"
expect \"root@localhost \[(none)\]>\"
send \"GRANT ALL PRIVILEGES ON $NEW_DB_NAME.* TO '$NEW_DB_USER_NAME'@'localhost';\r\"
expect \"root@localhost \[(none)\]>\"
send \"FLUSH PRIVILEGES;\r\"
expect \"root@localhost \[(none)\]>\"
send \"exit\r\"
expect eof
")

echo "$NEW_DATABASE"

echo 'The database for WordPress has been configured. Moving on.'
# Downloading and configuring WordPress announcement
echo "WordPress is now being downloaded and pre-configured."

# Fetch Wordpress from the official site
wget -O /root/latest.tar.gz https://wordpress.org/latest.tar.gz

# Unpack Wordpress
tar -zxf /root/latest.tar.gz -C /root

# Create the main config file from the sample
cp /root/wordpress/wp-config-sample.php /root/wordpress/wp-config.php

# Add the database name into the wp-config.php file
NEW_DB=$(cat /root/new_db_name.txt) && export NEW_DB
sed -i -e 's/database_name_here/'"$NEW_DB"'/g' /root/wordpress/wp-config.php

# Add the username into the wp-config.php file
USER_NAME=$(cat /root/new_db_user_name.txt) && export USER_NAME
sed -i -e 's/username_here/'"$USER_NAME"'/g' /root/wordpress/wp-config.php

# Add the db password into the wp-config.php file
PASSWORD=$(cat /root/newdb_pwd.txt) && export PASSWORD
sed -i -e 's/password_here/'"$PASSWORD"'/g' /root/wordpress/wp-config.php

## Add the socket where MariaDB is running
# sed -i -e 's/localhost/localhost:\/var\/run\/mysql\/mysql.sock/g' /root/wordpress/wp-config.php

# Move the content of the wordpress file into the DocumentRoot path
cp -r /root/wordpress/* /var/www/html

# Change the ownership of the DocumentRoot path content from root to the Apache HTTP user (named www)
chown -R apache:apache /var/www/html

# Make WordPress root directory read only
chcon -t httpd_sys_content_t /var/www/html -R

# Allow read and write into the wp-content folder in WordPress and wp-config.php for updates and plugin installs
chcon -t httpd_sys_rw_content_t /var/www/html/wp-config.php
chcon -t httpd_sys_rw_content_t /var/www/html/wp-content -R

# No one but root can read these files. Read only permissions.
chmod 400 /root/new_db_name.txt
chmod 400 /root/new_db_user_name.txt
chmod 400 /root/newdb_pwd.txt

# Display the new database, username and password generated on MySQL to accomodate WordPress
echo "Your NEW_DB_NAME is written on this file /root/new_db_name.txt"
echo "Your NEW_DB_USER_NAME is written on this file /root/new_db_user_name.txt"
echo "Your NEW_DB_PASSWORD is written on this file /root/newdb_pwd.txt"

# Actions on the CLI are now finished.
echo 'Actions on the CLI are now finished. Please visit the ip/domain of the site with a browser and proceed with the install'

# Uncomment the line below to display the location of the generated root password for MariaDB
# if you've uncommented the use of pwgen in the MariaDB install
# echo "Your DB_ROOT_PASSWORD is written on this file /root/db_root_pwd.txt"

# Sources:
# https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mysql-php-lamp-stack-on-centos-7
# https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-centos-7-servers
# https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mariadb-php-lamp-stack-on-debian-10
