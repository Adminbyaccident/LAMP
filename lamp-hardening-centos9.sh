#!/usr/bin/bash
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: lamp-hardening-centos9.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 22-01-2023
# SET FOR: Beta
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: CentOS Stream 9
#
# PURPOSE: This script installs some security tools and configurations on a LAMP system based on CentOS Stream 9
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
echo 'Installing Fail2ban for SSH'
dnf install -y epel-release
dnf update -y
dnf install -y fail2ban fail2ban-firewalld
systemctl enable fail2ban
systemctl start fail2ban

# Status message
echo 'Configuring Fail2ban'
cp /etc/fail2ban/jail.d/00-firewalld.conf /etc/fail2ban/jail.d/00-firewalld.local
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sed -i -e 's/banaction = iptables-multiport/banaction = firewallcmd-rich-rules[actiontype=]/g' /etc/fail2ban/jail.local
sed -i -e 's/banaction_allports = iptables-allports/banaction_allports = firewallcmd-rich-rules[actiontype=]/g' /etc/fail2ban/jail.local
systemctl restart fail2ban

# Status message
echo 'Configuring Fail2ban for SSH'
touch /etc/fail2ban/jail.d/01-sshd.local
echo '
[sshd]

enabled = true
port    = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
bantime = 10m
findtime = 10m
maxretry = 5
' >> /etc/fail2ban/jail.d/01-sshd.local
systemctl restart fail2ban

# Status message
echo 'Hardening Apache HTTP'

# Removing the OS type and modifying version banner (no mod_security here). 
# ServerTokens will only display the minimal information possible.
echo 'ServerTokens Prod' >> /etc/httpd/conf/httpd.conf

# ServerSignature will disable the server exposing its type.
echo 'ServerSignature Off' >> /etc/httpd/conf/httpd.conf

# Disable the TRACE method.
echo 'TraceEnable off' >> /etc/httpd/conf/httpd.conf

# Status message
echo 'Installing ModSecurity Web Application Firewall for Apache HTTP'

# Install ModSecurity
dnf install -y mod_security

# Install CRS ruleset for ModSecurity
dnf install -y git
wget -O /etc/httpd/modsecurity.d/crs-ruleset-3.3.4.zip https://github.com/coreruleset/coreruleset/archive/refs/tags/v3.3.4.zip
dnf install -y unzip
unzip /etc/httpd/modsecurity.d/crs-ruleset-3.3.4.zip -d /etc/httpd/modsecurity.d/
cp /etc/httpd/modsecurity.d/coreruleset-3.3.4/crs-setup.conf.example /etc/httpd/modsecurity.d/coreruleset-3.3.4/crs-setup.conf
cp /etc/httpd/modsecurity.d/coreruleset-3.3.4/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example /etc/httpd/modsecurity.d/coreruleset-3.3.4/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
cp /etc/httpd/modsecurity.d/coreruleset-3.3.4/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example /etc/httpd/modsecurity.d/coreruleset-3.3.4/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf
echo '
<IfModule mod_security2.c>
    # ModSecurity Core Rules Set and Local configuration
        IncludeOptional /etc/httpd/modsecurity.d/coreruleset-3.3.4/*.conf
        IncludeOptional /etc/httpd/modsecurity.d/activated_rules/*.conf
        IncludeOptional /etc/httpd/modsecurity.d/local_rules/*.conf
        IncludeOptional /etc/httpd/modsecurity.d/coreruleset-3.3.4/rules/*.conf
</IfModule>
' >> /etc/httpd/conf.d/mod_security.conf

# Status message
echo 'Setting up .htaccess malicious queries blocking'

# Setting up custom Rewrite Rules to stop malicious requests

echo "
<IfModule mod_rewrite.c>
RewriteCond %{HTTP_USER_AGENT} (havij|libwww-perl|wget|python|nikto|curl|scan|java|winhttp|clshttp|loader) [NC,OR]
RewriteCond %{HTTP_USER_AGENT} (%0A|%0D|%27|%3C|%3E|%00) [NC,OR]
RewriteCond %{HTTP_USER_AGENT} (;|<|>|'|\"|\)|\(|%0A|%0D|%22|%27|%28|%3C|%3E|%00).*(libwww-perl|wget|python|nikto|curl|scan|java|winhttp|HTTrack|clshttp|archiver|loader|email|harvest|extract|grab|miner|fetch) [NC,OR]
RewriteCond %{THE_REQUEST} (\?|\*|%2a)+(%20+|\\\s+|%20+\\\s+|\\\s+%20+|\\\s+%20+\\\s+)(http|https)(:/|/) [NC,OR]
RewriteCond %{THE_REQUEST} etc/passwd [NC,OR]
RewriteCond %{THE_REQUEST} cgi-bin [NC,OR]
RewriteCond %{THE_REQUEST} (%0A|%0D|\\r|\\n) [NC,OR]
RewriteCond %{REQUEST_URI} owssvr\.dll [NC,OR]
RewriteCond %{HTTP_REFERER} (%0A|%0D|%27|%3C|%3E|%00) [NC,OR]
RewriteCond %{HTTP_REFERER} \.opendirviewer\. [NC,OR]
RewriteCond %{HTTP_REFERER} users\.skynet\.be.* [NC,OR]
RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=(http|https):// [NC,OR]
RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=(\.\.//?)+ [NC,OR]
RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=/([a-z0-9_.]//?)+ [NC,OR]
RewriteCond %{QUERY_STRING} \=PHP[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12} [NC,OR]
RewriteCond %{QUERY_STRING} (\.\./|%2e%2e%2f|%2e%2e/|\.\.%2f|%2e\.%2f|%2e\./|\.%2e%2f|\.%2e/) [NC,OR]
RewriteCond %{QUERY_STRING} ftp\: [NC,OR]
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
RewriteCond %{QUERY_STRING} base64_encode.*\(.*\) [NC,OR]
RewriteCond %{QUERY_STRING} base64_(en|de)code[^(]*\([^)]*\) [NC,OR]
RewriteCond %{QUERY_STRING} GLOBALS(=|\[|\%[0-9A-Z]{0,2}) [OR]
RewriteCond %{QUERY_STRING} _REQUEST(=|\[|\%[0-9A-Z]{0,2}) [OR]
RewriteCond %{QUERY_STRING} ^.*(\(|\)|<|>|%3c|%3e).* [NC,OR]
RewriteCond %{QUERY_STRING} ^.*(\x00|\x04|\x08|\x0d|\x1b|\x20|\x3c|\x3e|\x7f).* [NC,OR]
RewriteCond %{QUERY_STRING} (NULL|OUTFILE|LOAD_FILE) [OR]
RewriteCond %{QUERY_STRING} (\.{1,}/)+(motd|etc|bin) [NC,OR]
RewriteCond %{QUERY_STRING} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{QUERY_STRING} (<|>|''|%0A|%0D|%27|%3C|%3E|%00) [NC,OR]
RewriteCond %{QUERY_STRING} concat[^\(]*\( [NC,OR]
RewriteCond %{QUERY_STRING} union([^s]*s)+elect [NC,OR]
RewriteCond %{QUERY_STRING} union([^a]*a)+ll([^s]*s)+elect [NC,OR]
RewriteCond %{QUERY_STRING} \-[sdcr].*(allow_url_include|allow_url_fopen|safe_mode|disable_functions|auto_prepend_file) [NC,OR]
RewriteCond %{QUERY_STRING} (;|<|>|'|\"|\)|%0A|%0D|%22|%27|%3C|%3E|%00).*(/\*|union|select|insert|drop|delete|update|cast|create|char|convert|alter|declare|order|script|set|md5|benchmark|encode) [NC,OR]
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
RewriteCond %{QUERY_STRING} (sp_executesql) [NC]
RewriteRule ^(.*)$ - [F]
</IfModule>
" >> /var/www/html/.htaccess

