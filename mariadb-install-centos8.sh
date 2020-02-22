#!/usr/bin/bash

# This is an install script for CentOS systems in order to automate the MariaDB installation process.
# Tune it up to your needs and please, change the password.

# Update the system sources
yum update -y

# Upgrade the system before moving forward
yum upgrade -y

# Install MariaDB
yum install -y mariadb-server mariadb

# Enable MariaDB to start up at boot time
systemctl enable mariadb.service

# Start up MariaDB service
systemctl start mariadb.service

# Install expect so the mysql_secure_installation script can be automated
yum install -y expect

# This below is the actual Expect script. Change the password!!!
# Not changing the password found on this script on the internet is a huge security risk.
 
SECURE_MYSQL=$(expect -c "
set timeout 2
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"\r\"
expect \"Set root password? \[Y/n\]\"
send \"y\r\"
expect \"New password:\"
send \"albert-XP24\r\"
expect \"Re-enter new password:\"
send \"albert-XP24\r\"
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

# Now MariaDB has been installed you may not need expect anymore.
# Uncomment the line below to remove expect.
# yum remove -y expect
