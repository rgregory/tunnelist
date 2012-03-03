#!/bin/bash
#
set -u
set -e

[ -e /command/ ] || ( echo "Need Daemontools" && exit 1)

DEPLOY="createKey.sh firewall.sh genUser.sh rshell"

for all in $DEPLOY; do
	cp -v scripts/$all /usr/local/bin/$all
done 

if [ ! `grep rshell /etc/shells` ]; then
     echo "/usr/local/bin/rshell" >> /etc/shells
fi

mkdir /etc/tunnelist

mv /etc/security/limits.conf /etc/security/limits.conf.orig
cp -v cfg/limits.conf /etc/security/limits.conf
mv /etc/login.defs /etc/login.defs.orig
cp -v cfg/logins.defs /etc/login.defs
cp -v cfg/sshd_config /etc/tunnelist/
cp -v cfg/ssmtp.conf /etc/
mv /etc/sysctl.conf /etc/sysctl.conf.orig
cp -v cfg/sysctl.conf /etc/sysctl.conf

# Firewall
# 
chmod +x /usr/local/bin/*
echo "/usr/local/bin/firewall.sh" >> /etc/rc.local

# Daemontools
#
cp -rv supervised/* /etc/tunnelist/
chmod +x /etc/tunnelist/run /etc/tunnelist/log/run
