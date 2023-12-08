#!/bin/bash
#$t@$h
# This script removes binaries that can result a file download.
# It DOES modify your system. Run as root and use with caution.
binaries=(
    /usr/bin/aria2c
    /usr/bin/axel
    /usr/bin/curl
    /usr/bin/elinks
    /usr/bin/ftp
    /usr/bin/git
    /usr/bin/http
    /usr/bin/https
    /usr/bin/links
    /usr/bin/links2
    /usr/bin/lftp
    /usr/bin/lynx
    /usr/bin/mosh
    /usr/bin/rsync
    /usr/bin/scp
    /usr/bin/sftp
    /usr/bin/ssh
    /usr/bin/telnet
    /usr/bin/w3m
    /usr/bin/wget
    /usr/bin/apt
    /usr/bin/apt-get
    /usr/bin/dpkg
    /usr/bin/dpkg-deb
    /usr/bin/dpkg-query
    /usr/lib/apt/apt-helper
    /usr/lib/apt/methods/http
    /usr/lib/apt/methods/https
    /usr/lib/apt/methods/ftp
    /usr/lib/apt/methods/mirror
    /usr/lib/apt/methods/rsh
    /usr/lib/apt/methods/ssh
    /usr/lib/apt/methods/store
)

for binary in "${binaries[@]}"; do
    if [ -f "$binary" ]; then
        sudo rm -f "$binary"
    fi
done
