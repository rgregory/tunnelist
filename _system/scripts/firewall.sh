#!/bin/bash
#
# Tunnelist firewall configuration
#

set -u
set -e

IPT="/sbin/iptables"

# Enhancements
#
ANTI_SPOOF="YES"                    # perform source validation
NO_SOURCE_ROUTE="YES"               # ignore source routing
NO_ICMP_REDIRECT="YES"              # disable ICMP redirects
ICMP_ECHOREPLY_RATE="30"            # rate *kernel* responces to ICMP echos
LOG_MARTIANS="NO"                   # log packets with impossible addresses
SYN_COOKIES="YES"                   # enable TCP syncookies
ECN="NO"                            # enable ECN
TCP_TS="NO"                         # enable timestamps as per RFC1323
ICMP_IGNORE_BROADCASTS="YES"        # ignore ICMP echos
ICMP_IGNORE_BOGUS_ERROR="YES"       # ignore bogus icmp errors

# performance options
#
TCP_KEEP_ALIVE="3600"               # kernel default is 7200
TCP_FIN_TIMEOUT="30"                # kernel default is 60
TCP_WINDOW_SCALING="1"              # kernel default is enabled

# Default tables
#
$IPT -P INPUT DROP
$IPT -P OUTPUT ACCEPT
$IPT -P FORWARD DROP

# Allow loopback always
#
$IPT -A INPUT -i lo -s 127.0.0.1 -d 127.0.0.1 -j ACCEPT

# Drop nonsense immediately
#
$IPT -A INPUT -m state --state INVALID -j DROP
$IPT -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
$IPT -A INPUT -p tcp --tcp-flags ALL NONE -m state ! --state ESTABLISHED -j DROP
$IPT -A INPUT -p tcp --tcp-flags ALL ALL -m state ! --state ESTABLISHED -j DROP
$IPT -A INPUT -p tcp --tcp-flags ALL FIN -m state ! --state ESTABLISHED -j DROP

# Customer chain
#
#
$IPT -A INPUT -p tcp -m state --state NEW -m multiport --dports 22,23,53,443,548,587 -j ACCEPT
$IPT -A INPUT -p tcp -m state --state NEW -m multiport --dports 2212 -j ACCEPT

# Web front
#
$IPT -A INPUT -p tcp -m state --state NEW --dport 80 -m connlimit --connlimit-above 100 --connlimit-mask 24 -j REJECT
$IPT -A INPUT -p tcp -m state --state NEW --dport 80 -j ACCEPT

# Flow
#
$IPT -A INPUT -p tcp -m state --state ESTABLISHED,RELATED -m multiport --dports 22,23,53,443,548,587 -j ACCEPT
$IPT -A INPUT -p tcp -m state --state ESTABLISHED,RELATED -m multiport --dports 80,2212 -j ACCEPT

# Other
#
$IPT -A INPUT -p udp -j REJECT
$IPT -A INPUT -p icmp -m limit --limit 100/s -j ACCEPT
$IPT -A INPUT -j DROP

# Linux allows us to configure standard features of
# the TCP stack for performance and security measures.

# Ensure ip-forwarding is disabled at onset
#
echo "0" > /proc/sys/net/ipv4/ip_forward

# Anti-spoofing blocks
#
if [ "$ANTI_SPOOF" = "YES" -o "$ANTI_SPOOF" = "yes" ]; then
   for a in /proc/sys/net/ipv4/conf/*/rp_filter;
       do
           echo 1 > $a
       done
fi

# no source routes
#
if [ "$NO_SOURCE_ROUTE" = "YES" -o "$NO_SOURCE_ROUTE" = "yes" ]; then
   for z in /proc/sys/net/ipv4/conf/*/accept_source_route;
       do
           echo 0 > $z
   done
fi

# TCP SYN cookies
#
if [ "$SYN_COOKIES" = "YES" -o "$SYN_COOKIES" = "yes" ]; then
   test -f /proc/sys/net/ipv4/tcp_syncookies && echo 1 > /proc/sys/net/ipv4/tcp_syncookies
else
   test -f /proc/sys/net/ipv4/tcp_syncookies && echo 0 > /proc/sys/net/ipv4/tcp_syncookies
fi

# ICMP redirects
#
if [ "$ICMP_REDIRECT" = "YES" -o "$ICMP_REDIRECT" = "yes" ]; then
   for f in /proc/sys/net/ipv4/conf/*/accept_redirects;
       do
           echo 0 > $f
   done
fi

# Ensure oddball addresses are logged
#
if [ "$LOG_MARTIANS" = "YES" -o "$LOG_MARTIANS" = "yes" ]; then
   echo 1 > /proc/sys/net/ipv4/conf/all/log_martians
else
   echo 0 > /proc/sys/net/ipv4/conf/all/log_martians
fi

# ECN
#
if [ "$ECN" = "YES" -o "$ECN" = "yes" ]; then
   test -f /proc/sys/net/ipv4/tcp_ecn && echo "1" > /proc/sys/net/ipv4/tcp_ecn
else
   test -f /proc/sys/net/ipv4/tcp_ecn && echo "0" > /proc/sys/net/ipv4/tcp_ecn
fi

# tcp timestamps
#
if [ "$TCP_TS" = "NO" -o "$TCP_TS" = "no" ]; then
   echo 0 > /proc/sys/net/ipv4/tcp_timestamps
else
   echo 1 > /proc/sys/net/ipv4/tcp_timestamps
fi

# icmp broadcasts
#
if [ "$ICMP_IGNORE_BROADCASTS" = "YES" -o "$ICMP_IGNORE_BROADCASTS" = "yes" ]; then
   echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
else
   echo 0 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
fi

# icmp reply rate
#
if [ "$ICMP_ECHOREPLY_RATE" != "0" ];
   then
       if [ ! "$(echo $ICMP_ECHOREPLY_RATE | grep -E '[[:digit:]]')" ]; then
           SYSLOG "ERROR: invalid value for ICMP_ECHOREPLY_RATE"
       else
           echo $ICMP_ECHOREPLY_RATE > /proc/sys/net/ipv4/icmp_echoreply_rate
           SYSLOG "setting ICMP_ECHOREPLY_RATE to $ICMP_ECHOREPLY_RATE"
       fi
fi

# "bogus" icmp responses
#
if [ "$ICMP_IGNORE_BOGUS_ERROR" = "YES" -o "$ICMP_IGNORE_BOGUS_ERROR" = "yes" ]; then
   echo "1" > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses
else
   echo "0" > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses
fi

# hardening options
#
echo $TCP_KEEP_ALIVE > /proc/sys/net/ipv4/tcp_keepalive_time
echo $TCP_FIN_TIMEOUT >  /proc/sys/net/ipv4/tcp_fin_timeout
echo $TCP_WINDOW_SCALING > /proc/sys/net/ipv4/tcp_window_scaling

# Go go gadget shape
# We shape *everything*
#
/sbin/tc qdisc del dev eth0 root
/sbin/tc qdisc add dev eth0 root handle 1:0 htb default 100
/sbin/tc class add dev eth0 parent 1:0 classid 1:100 htb rate 10mbps ceil 15mbps prio 0
/sbin/tc filter add dev eth0 parent 1:0 prio 0 protocol ip handle 100 fw flowid 1:100

# tc -s class show dev eth0
# tc -s qdisc ls dev eth0
# tc -s class show dev eth0 | ./tccs 

