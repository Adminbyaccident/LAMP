#!/usr/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: fedora_auto-updates.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 19-04-2022
# SET FOR: Test
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: Fedora 35
#
# PURPOSE: This script installs the automatic updates on Fedora, configures them and enables them.
#
# REV LIST:
# DATE: 19-04-2022
# BY: ALBERT VALBUENA
# MODIFICATION: 19-04-2022
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!

##########################################################
################ BEGINNING OF MAIN #######################
##########################################################

# Update the whole system
dnf -y update

# Install the auto-updates package
dnf -y install dnf-automatic

# Configure updates not just to be downloaded but to be applied
sed -i -e '/apply_updates/s/no/yes' /etc/dnf/automatic.conf

# Enable the timer to periodically check for updates and perform them when available
systemctl enable --now dnf-automatic.timer

## EOF
