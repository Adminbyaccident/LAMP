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

# Hide Apache HTTP Server information
echo "ServerSignature Off" >> /etc/httpd/conf/httpd.conf
echo "ServerTokens Prod" >> /etc/httpd/conf/httpd.conf

# Add secure headers
touch /etc/httpd/conf.modules.d/headers.conf
echo "
<IfModule mod_headers.c>
        # Add security and privacy related headers
        Header set Content-Security-Policy \"upgrade-insecure-requests;\"
        Header always edit Set-Cookie (.*) \"\$1; HttpOnly; Secure\"
        Header set Strict-Transport-Security \"max-age=31536000; includeSubDomains\"
        Header set X-Content-Type-Options \"nosniff\"
        Header set X-XSS-Protection \"1; mode=block\"
        Header set X-Robots-Tag \"all\"
        Header set X-Download-Options \"noopen\"
        Header set X-Permitted-Cross-Domain-Policies \"none\"
        Header always set Referrer-Policy: \"strict-origin\"
        Header set X-Frame-Options: \"deny\"
        Header set Permissions-Policy: \"accelerometer=(none); ambient-light-sensor=(none); autoplay=(none); battery=(none); display-capture=(none); document-domain=(none); encrypted-media=(self); execution-while-not-rendered=(none); execution-while-out-of-viewport=(none); geolocation=(none); gyroscope=(none); layout-animations=(none); legacy-image-formats=(self); magnometer=(none); midi=(none); camera=(none); notifications=(none); microphone=(none); speaker=(none); oversized-images=(self); payment=(none); picture-in-picture=(none); publickey-credentials-get=(none); sync-xhr=(none); usb=(none); vr=(none); wake-lock=(none); screen-wake-lock=(none); web-share=(none); xr-partial-tracking=(none)\"
        SetEnv modHeadersAvailable true
</IfModule>" >>  /etc/httpd/conf.modules.d/headers.conf

echo " 
Include /etc/httpd/conf.modules.d/headers.conf
" >> /etc/httpd/conf/httpd.conf

# Disable the TRACE method.
echo 'TraceEnable off' >> /etc/httpd/conf/httpd.conf

# Allow specific HTTP methods.
echo "
<Directory "/var/www">
    <LimitExcept GET POST HEAD>
        deny from all
    </LimitExcept>
</Directory>" >> /etc/httpd/conf/httpd.conf

# Create the file which will contain the WAF like rules.
touch /etc/httpd/conf.modules.d/00-waf-like.conf

# Inject the rules into the file.
echo "
# WAF-LIKE RULES FOR A FAMP STACK 
<IfModule mod_rewrite.c>
RewriteEngine on

# Condition to block suspicious request methods.
RewriteCond %{REQUEST_METHOD} ^(HEAD|TRACE|DELETE|TRACK|DEBUG) [NC,OR]

# Condition to block the specified user agents from programs and bots.
RewriteCond %{HTTP_USER_AGENT} (havij|libwww-perl|wget|python|nikto|curl|scan|java|winhttp|clshttp|loader|fetch) [NC,OR]
RewriteCond %{HTTP_USER_AGENT} (%0A|%0D|%27|%3C|%3E|%00) [NC,OR]
RewriteCond %{HTTP_USER_AGENT} (;|<|>|'|\"|\)|\(|%0A|%0D|%22|%27|%28|%3C|%3E|%00).*(libwww-perl|wget|python|nikto|curl|scan|java|winhttp|HTTrack|clshttp|archiver|loader|email|harvest|extract|grab|miner) [NC,OR]

# Condition to block suspicious header requests.
RewriteCond %{HTTP_ACCEPT} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP_COOKIE} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP_FORWARDED} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP_HOST} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP_PROXY_CONNECTION} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP_REFERER} (localhost|loopback|127\.0\.0\.1) [NC,OR]

# Condition to block Proxy/LoadBalancer/WAF bypass
RewriteCond %{HTTP:X-Client-IP} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Forwarded-For} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Forwarded-Scheme} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Real-IP} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Forwarded-By} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Originating-IP} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Forwarded-From} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Forwarded-Host} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Remote-Addr} (localhost|loopback|127\.0\.0\.1) [NC,OR]

# Condition to block requests that incorporate the specified expressions in them. Avoid injection.
RewriteCond %{THE_REQUEST} (\?|\*|%2a)+(%20+|\\s+|%20+\\s+|\\s+%20+|\\s+%20+\\s+)(http|https)(:/|/) [NC,OR]

# Condition to block any request containing the etc/passwd string and avoid system passwords exfiltration.
RewriteCond %{THE_REQUEST} etc/passwd [NC,OR]

# Condition to block the execution of CGI programs.
RewriteCond %{THE_REQUEST} cgi-bin [NC,OR]

# Condition to block requests that jump into the next line. Avoid injection.
RewriteCond %{THE_REQUEST} (%0A|%0D|\\r|\\n) [NC,OR]

# Condition to block any Sharepoint services call.
RewriteCond %{REQUEST_URI} owssvr\.dll [NC,OR]

# Condition to block requests that simulate to come from the specified expressions. Avoid injection.
RewriteCond %{HTTP_REFERER} (%0A|%0D|%27|%3C|%3E|%00) [NC,OR]
RewriteCond %{HTTP_REFERER} \.opendirviewer\. [NC,OR]
RewriteCond %{HTTP_REFERER} users\.skynet\.be.* [NC,OR]

# Condition to block requests that incorporate the specified expressions in them.
RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=(http|https):// [NC,OR]
RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=(\.\.//?)+ [NC,OR]
RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=/([a-z0-9_.]//?)+ [NC,OR]

# Condition to block any PHP execution. Avoid injection.
RewriteCond %{QUERY_STRING} \=PHP[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12} [NC,OR]
RewriteCond %{QUERY_STRING} (\.\./|%2e%2e%2f|%2e%2e/|\.\.%2f|%2e\.%2f|%2e\./|\.%2e%2f|\.%2e/) [NC,OR]

# Condition to block FTP usage. Avoid uploads.
RewriteCond %{QUERY_STRING} ftp\: [NC,OR]

# Condition to block any requests jumping over paths or injecting/retrieving objects.
RewriteCond %{QUERY_STRING} (http|https)\: [NC,OR]
RewriteCond %{QUERY_STRING} \=\|w\| [NC,OR]
RewriteCond %{QUERY_STRING} ^(.*)/self/(.*)$ [NC,OR]
RewriteCond %{QUERY_STRING} ^(.*)cPath=(http|https)://(.*)$ [NC,OR]
RewriteCond %{QUERY_STRING} (\<|%3C).*script.*(\>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} (<|%3C)([^s]*s)+cript.*(>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} (\<|%3C).*embed.*(\>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} (<|%3C)([^e]*e)+mbed.*(>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} (\<|%3C).*object.*(\>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} (<|%3C)([^o]*o)+bject.*(>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} (\<|%3C).*iframe.*(\>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} (<|%3C)([^i]*i)+frame.*(>|%3E) [NC,OR]

# Condition to block with the intention to en/de-code strings in base64
RewriteCond %{QUERY_STRING} base64_encode.*\(.*\) [NC,OR]
RewriteCond %{QUERY_STRING} base64_(en|de)code[^(]*\([^)]*\) [NC,OR]

# Condition to block
RewriteCond %{QUERY_STRING} GLOBALS(=|\[|\%[0-9A-Z]{0,2}) [OR]
RewriteCond %{QUERY_STRING} _REQUEST(=|\[|\%[0-9A-Z]{0,2}) [OR]

# Condition to block requests that incorporate the specified expressions in them. Avoid injection.
RewriteCond %{QUERY_STRING} ^.*(\(|\)|<|>|%3c|%3e).* [NC,OR]
RewriteCond %{QUERY_STRING} ^.*(\x00|\x04|\x08|\x0d|\x1b|\x20|\x3c|\x3e|\x7f).* [NC,OR]

# Condition to block requests which declare the specified values in the string query. Avoid injection.
RewriteCond %{QUERY_STRING} (NULL|OUTFILE|LOAD_FILE) [OR]

# Condition to block requests intending to retrieve or inject content in the motd file or /etc and /bin directories.
RewriteCond %{QUERY_STRING} (\.{1,}/)+(motd|etc|bin) [NC,OR]

# Condition to block any string referencing to the host or loopback interface.
RewriteCond %{QUERY_STRING} (localhost|loopback|127\.0\.0\.1) [NC,OR]

# Condition to block requests that incorporate the specified expressions in them. Avoid injection.
RewriteCond %{QUERY_STRING} (<|>|'|%0A|%0D|%27|%3C|%3E|%00) [NC,OR]

# Condition to block SQL injection attacks 
RewriteCond %{QUERY_STRING} concat[^\(]*\( [NC,OR]
RewriteCond %{QUERY_STRING} union([^s]*s)+elect [NC,OR]
RewriteCond %{QUERY_STRING} union([^a]*a)+ll([^s]*s)+elect [NC,OR]
RewriteCond %{QUERY_STRING} \-[sdcr].*(allow_url_include|allow_url_fopen|safe_mode|disable_functions|auto_prepend_file) [NC,OR]
RewriteCond %{QUERY_STRING} (;|<|>|'|\"|\)|%0A|%0D|%22|%27|%3C|%3E|%00).*(/\*|union|select|insert|drop|delete|update|cast|create|char|convert|alter|declare|order|script|set|md5|benchmark|encode) [NC,OR]
RewriteCond %{QUERY_STRING} (sp_executesql) [NC]

# The rewrite rule itself. Any match on the above gets blocked.
RewriteRule ^(.*)$ - [F]

</IfModule>
" >> /etc/httpd/conf.modules.d/00-waf-like.conf

# Restart Apache HTTP for the changes to be applied
systemctl restart httpd

# Warning message
echo 
"There are two missing security modules as of yet in this script. 
One is mod_evasive and the other one is mod_security.
Use this at you own discretion"
