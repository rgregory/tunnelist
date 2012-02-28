#!/bin/bash
#
USERNAME=$1
USEREMAIL=$2
PASSWORD=$3
TOKEN=$4
EXPIRE=""
GROUP="customers"
SHELL="/usr/local/bin/rshell"
AU="/usr/sbin/adduser"
PSWD="/usr/bin/passwd"

# Sanity checks
#
if [ ! `grep rshell /etc/shells` ]; then
     exit 1
fi

# Create user
#
$AU -C "$USEREMAIL,$TOKEN" -f 0 -M -e $EXPIRES -g $GROUP -n -s $SHELL $USERNAME
echo "$PASSWORD" | passwd --stdin $USERNAME
