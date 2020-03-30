# LAMP
This is a collection of scripts to build different LAMP servers.

## The lamp-centos8.sh script
This script will build a LAMP stack on CentOS 8 following instructions from these sources:

https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mysql-php-lamp-stack-on-centos-7
https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-centos-7-servers

## The lamp-debian10.sh script
This script will build a LAMP stack on Debian 10 following instructions from these sources:

https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mariadb-php-lamp-stack-on-debian-10
https://www.adminbyaccident.com/gnu-linux/lamp-stack-debian/

## The lamp-ubuntu1804.sh script
This script will build a LAMP stack on Ubuntu 18.04 following instructions from these sources:

https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mariadb-php-lamp-stack-on-debian-10
https://www.adminbyaccident.com/gnu-linux/lamp-stack-debian/

I chose the Debian install because the Ubuntu one at DOcean uses MySQL. The script changes a bit on de DB part of it if you choose that route. I'll put more scripts with tuneables down below in the near future.

## The lamp-ubuntu1804_mysql.sh script
This one is basically the same as above but using MySQL instead of MariaDB. The source is:

https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mysql-php-lamp-stack-ubuntu-18-04

## The mariadb-install-centos8.sh script
This will install MariaDB on the default repositories found on a CentOS 8 install. As a reference, you may follow this guide to understand / change the script.

https://www.digitalocean.com/community/tutorials/how-to-install-mariadb-on-centos-7

## The mariadb-install-debian10.sh
This as with the CentOS version will install MariaDB on the default repositories found on a Debian 10 install. Be aware of Debian ways for the database root password. There are a few links on the script to better understand this. As a reference, you may follow this guide to understand / change the script:

https://www.digitalocean.com/community/tutorials/how-to-install-mariadb-on-debian-10
