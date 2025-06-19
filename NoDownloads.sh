#!/bin/bash
#$t@$h
# This script removes binaries that can result a file download.
# It DOES modify your system. RUN AS ROOT and use with caution.
# Have added a lock and unlock feature:
# Usage: ./NoDownloads.sh [lock || unlock]
BACKUP_DIR="/var/lib/binary_locker"
BACKUP_ZIP="$BACKUP_DIR/binaries.zip"
TMP_RESTORE_DIR="/tmp/binary_restore"

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

if [[ "$EUID" -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

mkdir -p "$BACKUP_DIR"

case "${1:-}" in
  lock)
    echo "Locking: Backing up and removing binaries."

    tmp_copy_dir="$(mktemp -d)"
    for binary in "${binaries[@]}"; do
      if [ -f "$binary" ]; then
        mkdir -p "$tmp_copy_dir$(dirname "$binary")"
        cp -a "$binary" "$tmp_copy_dir$binary"
        rm -f "$binary"
        echo "Removed: $binary"
      fi
    done

    (cd "$tmp_copy_dir" && zip -r "$BACKUP_ZIP" . > /dev/null)
    rm -rf "$tmp_copy_dir"
    echo "Binaries backed up to: $BACKUP_ZIP"
    ;;

  unlock)
    echo "Unlocking: Restoring missing binaries."

    if [ ! -f "$BACKUP_ZIP" ]; then
      echo "Backup zip not found at $BACKUP_ZIP"
      exit 1
    fi

    rm -rf "$TMP_RESTORE_DIR"
    mkdir -p "$TMP_RESTORE_DIR"
    unzip -q "$BACKUP_ZIP" -d "$TMP_RESTORE_DIR"

    for binary in "${binaries[@]}"; do
      if [ ! -f "$binary" ] && [ -f "$TMP_RESTORE_DIR$binary" ]; then
        mkdir -p "$(dirname "$binary")"
        cp -a "$TMP_RESTORE_DIR$binary" "$binary"
        echo "Restored: $binary"
      fi
    done

    rm -rf "$TMP_RESTORE_DIR"
    ;;

  *)
    echo "Usage: $0 lock|unlock"
    exit 1
    ;;
esac
