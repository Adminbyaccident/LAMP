#!/usr/bin/bash
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: tls-sef_signed-enable-lamp-9.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 28-02-2023
# SET FOR: Production
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: CentOS 9 / RHEL 9
#
# PURPOSE: This is an install script for TLS enablement with self-signed certificates
# on a LAMP stack on CentOS 9
#
# REV LIST:
# DATE: 28-02-2023
# BY: ALBERT VALBUENA
# MODIFICATION: 28-02-2023
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!

##########################################################
################ BEGINNING OF MAIN #######################
##########################################################

# Install the TLS module for Apache HTTP
dnf install -y mod_ssl

# Apply HTTP redirection to HTTPS

echo '
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
' >> /etc/httpd/conf/httpd.conf

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

# Restart Apache HTTP
systemctl restart httpd

# Final message
echo 'TLS has been enabled in this Apache HTTP server'
