#!/usr/bin/bash
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: mysql-install-centos8.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 18-12-2020
# SET FOR: Production
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: CentOS 8 / RHEL 8
#
# PURPOSE: This is an install script for MySQL 8 on CentOS 8
#
# REV LIST:
# DATE: 18-12-2020
# BY: ALBERT VALBUENA
# MODIFICATION: Creation
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!

##########################################################
########### DEFINE FILES AND VARIABLES HERE ##############
##########################################################



##########################################################
############### DEFINE FUNCTIONS HERE ####################
##########################################################



##########################################################
################ BEGINNING OF MAIN #######################
##########################################################

# Let's install MySQL database.
dnf install -y mysql-server mysql

# Enable MySQL service
systemctl enable mysqld

# Start up MySQL
systemctl start mysqld

# Install Expect so the MySQL secure installation process can be automated.
dnf install -y expect

# Make the hideous 'safe' install for MySQL.
##########################################################
################### IMPORTANT !!!! #######################
##########################################################

# Change the password found below!!!
# Not changing the password found on this script on the internet is a huge security risk.


SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Press y|Y for Yes, any other key for No:\"
send \"y\r\"
expect \"Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG:\"
send \"2\r\"
expect \"New password:\"
send \"QB_e-6qUe_vs521\r\"
expect \"Re-enter new password:\"
send \"QB_e-6qUe_vs521\r\"
expect \"Do you wish to continue with the password provided?(Press y|Y for Yes, any other key for No) :\"
send \"Y\r\"
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

echo "$SECURE_MYSQL"

# Sources:
# https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-centos-8

# End of script
