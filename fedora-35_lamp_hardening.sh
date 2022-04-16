#!/usr/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: fedora-35_lamp_hardening.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 16-04-2022
# SET FOR: Beta
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: Fedora 35
#
# PURPOSE: This script installs a full LAMP stack with Apache HTTP configured with MPM as Event + MariaDB 10.7 + PHP-FPM configured to read from the TCP socket
#
# REV LIST:
# DATE: 16-04-2022
# BY: ALBERT VALBUENA
# MODIFICATION: 16-04-2022
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!

##########################################################
################ BEGINNING OF MAIN #######################
##########################################################

# Install TLS capability for Apache HTTP
dnf -y install mod_ssl

# Create a self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/certs/server.key -out /etc/ssl/certs/server.crt -subj "/C=ES/ST=Barcelona/L=Terrassa/O=Adminbyaccident.com/CN=example.com/emailAddress=youremail@gmail.com"

# Configure TLS use
sed -i -e 's/#DocumentRoot/DocumentRoot/' /etc/httpd/conf.d/ssl.conf
sed -i -e '/#ServerName/s/#ServerName www.example.com:443/ServerName Fedora/' /etc/httpd/conf.d/ssl.conf
sed -i -e '/SSLCertificateFile \/etc\/pki/s/\/etc\/pki\/tls\/certs\/localhost.crt/\/etc\/pki\/tls\/certs\/server.crt/' /etc/httpd/conf.d/ssl.conf
sed -i -e '/SSLCertificateKeyFile \/etc\/pki/s/\/etc\/pki\/tls\/private\/localhost.key/\/etc\/pki\/tls\/certs\/server.key/' /etc/httpd/conf.d/ssl.conf

# Configure redirection from HTTP to HTTPS
echo "
<VirtualHost *:80>
    DocumentRoot /var/www/html
    ServerName www.example.com
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
</VirtualHost>
" >> /etc/httpd/conf.d/vhost.conf 

# Restart Apache HTTP so changes take effect
systemctl restart httpd
