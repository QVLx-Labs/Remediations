#!/bin/bash
#$t@$h
# This script locks up a system and does some diagnostics
# DISCLAIMER: This script is intended as action after an
# incident has been suspected. USE THIS LEGALLY/ETHICALLY
telinit 1

for interface in $(ip -o link show | awk -F': ' '{print $2}'); do
    ip link set $interface down
done

systemctl stop NetworkManager
systemctl stop networking
systemctl stop wpa_supplicant
systemctl disable NetworkManager
systemctl disable networking
systemctl disable wpa_supplicant

uname -a
uptime
df -h
free -m
ps auxf
last -a
netstat -tuln
cat /var/log/auth.log | tail -n 100
dmesg | tail -n 50
journalctl -xb | tail -n 100

# Can make this unlock conditional
telinit 2
