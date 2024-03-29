#!/usr/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: fedora-waf-like-rules.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 17-04-2022
# SET FOR: Test
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: Fedora 35
#
# PURPOSE: This script installs a full LAMP stack with Apache HTTP configured with MPM as Event + MariaDB 10.7 + PHP-FPM configured to read from the TCP socket
#
# REV LIST:
# DATE: 17-04-2022
# BY: ALBERT VALBUENA
# MODIFICATION: 17-04-2022
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!

##########################################################
################ BEGINNING OF MAIN #######################
##########################################################

# Create the file which will contain the WAF like rules.
touch /etc/httpd/conf.modules.d/waf-like.conf

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
" >> /etc/httpd/conf.modules.d/waf-like.conf

echo "Include /etc/httpd/conf.modules.d/waf-like.conf" >> /etc/httpd/conf/httpd.conf

# Restart Apache HTTP for the changes to be applied
systemctl restart httpd

## References:
## https://httpd.apache.org/docs/2.4/rewrite/intro.html
## https://httpd.apache.org/docs/current/mod/mod_rewrite.html
## http://mod-rewrite.org/book/
## For the owssvr.dll: https://docs.microsoft.com/en-us/previous-versions/office/developer/sharepoint-team-services/dd588689(v=office.11)?redirectedfrom=MSDN

## EOF
