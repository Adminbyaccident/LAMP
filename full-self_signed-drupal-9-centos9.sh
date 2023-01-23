#!/usr/bin/bash
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: full-self_signed-drupal-9-centos9.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 22-01-2023
# SET FOR: Beta
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: CentOS Stream 9
#
# PURPOSE: This script installs a Drupal 9 CMS on CentOS Stream 9
#
# REV LIST:
# DATE: 22-01-2023
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

# Status message
echo 'Updating the system'

# Let's update CentOS local repositories on this box.
dnf update -y

# Status message
echo 'Installing firewalld'
dnf install -y firewalld
systemctl enable firewalld
systemctl start firewalld

# Status message
echo 'Setting up firewall rules'

# Allow HTTP through the firewall
firewall-cmd --permanent --zone=public --add-service=ssh
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload

# Install EPEL repository
dnf install -y epel-release
dnf update -y

# Status message
echo 'Installing the LAMP stack.'

# Let's install Apache HTTP
dnf install -y httpd

# Enable Apache HTTP service
systemctl enable httpd

# Start Apache HTTP service
systemctl start httpd

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
# chmod 400 /root/db_root_pwd.txt

# Install PHP
dnf module enable -y php:8.1
dnf install -y php php-mysqlnd

# Enable PHP-FPM as a service
systemctl enable php-fpm

# Restart Apache HTTP 
systemctl restart httpd.service

# The Drupal adaptation for the LAMP scrip starts here

# Install the TLS module for Apache HTTP
dnf install -y mod_ssl

# Apply HTTP redirection to HTTPS

echo '
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
' >> /etc/httpd/conf/httpd.conf

# Installing missing dependencies
dnf install -y httpd-tools php php-cli php-json php-gd php-mbstring php-pdo php-xml php-mysqlnd php-pecl-zip wget

# Avoid PHP's information (version, etc) being disclosed
sed -i -e '/expose_php/s/expose_php = On/expose_php = Off/' /etc/php.ini

# Reload PHP-FPM
systemctl reload php-fpm

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

# Because Drupal and plugins will make use of an .htaccess file, let's enable it.
sed -i -e "156s/AllowOverride None/AllowOverride All/" /etc/httpd/conf/httpd.conf

# Create the DB for Drupal
# Create the database and user. Mind this is MariaDB
echo 'Creating a database for Drupal'

dnf install -y pwgen

touch /root/new_db_name.txt
touch /root/new_db_user_name.txt
touch /root/newdb_pwd.txt

echo "Generating new database, username and passoword for the Drupal install"

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

# Fetch Drupal 9 from the official site
wget -O /tmp/drupal-9.5.0.tar.gz https://ftp.drupal.org/files/projects/drupal-9.5.0.tar.gz

# Unpack Drupal 9
tar -zxf /tmp/drupal-9.5.0.tar.gz -C /tmp

# Create the main config file from the sample
cp /tmp/drupal-9.5.0/sites/default/default.settings.php /tmp/drupal-9.5.0/sites/default/settings.php

# Add the database name into the settings.php file
NEW_DB=$(cat /root/new_db_name.txt) && export NEW_DB
sed -i -e 's/databasename/'"$NEW_DB"'/g' /tmp/drupal-9.5.0/sites/default/settings.php

# Add the username into the settings.php file
USER_NAME=$(cat /root/new_db_user_name.txt) && export USER_NAME
sed -i -e 's/sqlusername/'"$USER_NAME"'/g' /tmp/drupal-9.5.0/sites/default/settings.php

# Add the db password into the settings.php file
PASSWORD=$(cat /root/newdb_pwd.txt) && export PASSWORD
sed -i -e 's/sqlpassword/'"$PASSWORD"'/g' /tmp/drupal-9.5.0/sites/default/settings.php

## Add the host parameter where MariaDB is running to the Drupal's settings.php configuration file. If not added it won't accept connections when installing.
sed -i '' -e '83s/localhost/127.0.0.1/g' /tmp/drupal-9.5.0/sites/default/settings.php

## Add the UNIX socket path 
sed -i '' -e '88i\
 *   '\'unix_socket\'\ \=\>\ \'/var\/run\/mysql\/mysql.sock\', /tmp/drupal-9.5.0/sites/default/settings.php
 
# Move the content of the Drupal 9 directory into the DocumentRoot path
cp -r /tmp/drupal-9.5.0/* /var/www/html
cp -r /tmp/drupal-9.5.0/.* /var/www/html

# Change the ownership of the DocumentRoot path content from root to the Apache HTTP user (named www)
chown -R apache:apache /var/www/html

echo 'Restarting services to load the new configuration for Drupal 9'

# Preventive services restart
systemctl restart httpd.service
systemctl restart php-fpm
systemctl restart mariadb

# No one but root can read these files. Read only permissions.
chmod 400 /root/new_db_name.txt
chmod 400 /root/new_db_user_name.txt
chmod 400 /root/newdb_pwd.txt

# Set SELinux in permissive mode for Apache HTTP and Drupal checks not to send you errors at install time.
semanage permissive -a httpd_t
semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html/(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/html/sites/default/settings.php'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/html/sites/default/files'
restorecon -Rv /var/www/html/
restorecon -v /var/www/html/sites/default/settings.php
restorecon -Rv /var/www/html/sites/default/files

# Display the new database, username and password generated on MySQL to accomodate Drupal 9
echo "Your DB_ROOT_PASSWORD is blank if you are root or a high privileged user"
echo "Your NEW_DB_NAME is written on this file /root/new_db_name.txt"
echo "Your NEW_DB_USER_NAME is written on this file /root/new_db_user_name.txt"
echo "Your NEW_DB_PASSWORD is written on this file /root/newdb_pwd.txt"

# Actions on the CLI are now finished.
echo 'Actions on the CLI are now finished. Please visit the ip/domain of the site with a web browser and proceed with the final steps of install'
