#!/bin/bash
# This script is part of the EventSentry repository
# Purpose - Script to add a user to Linux system including passsword.
# Also will grant the user access to start and stop services by creating a file
# with the same namne as the username inside sudoers.d
# -----------------------------------------------------------------------------
# Am i Root user?
if [ $(id -u) -eq 0 ]; then
        read -p "Enter username : " username
        egrep "^$username" /etc/passwd >/dev/null
        if [ $? -eq 0 ]; then
                echo "$username exists!"
                exit 1
        else
                useradd -m "$username"
                passwd "$username"
                echo $username ALL=NOPASSWD: /bin/systemctl start \* >/etc/sudoers.d/$username
                echo $username ALL=NOPASSWD: /bin/systemctl stop \* >>/etc/sudoers.d/$username
                echo $username ALL=NOPASSWD: /bin/systemctl start \* >>/etc/sudoers.d/$username
        fi
else
        echo "Only root may add a user to the system."
        exit 2
fi
