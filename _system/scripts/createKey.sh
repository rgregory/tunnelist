#!/bin/bash
#
set -u
set -e

PASS=""
USERMAIL=""
USERNAME=""
GEN="/usr/sbin/ssh-keygen"

mkdir -p $HOME/$USERNAME/.ssh/ || exit 1
$GEN -C $USERMAIL -f $HOME/$USERNAME/.ssh/`date +%m.%d.%Y.%S`.key -t dsa -N $PASS
