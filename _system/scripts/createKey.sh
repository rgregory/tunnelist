#!/bin/bash
#
# Create SSH keys for customer use
#
# Expect 3 variables via STDIN:

PASS="CUSTOMER-PASSPHRASE"
USERMAIL="foo@bar.com"
USERNAME=""
GEN="/usr/sbin/ssh-keygen"

mkdir -p $HOME/$USERNAME/.ssh/
$GEN -C $USERMAIL -f $HOME/$USERNAME/.ssh/`date +%m.%d.%Y.%S`.key -t dsa -N $PASS