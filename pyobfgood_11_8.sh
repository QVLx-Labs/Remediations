#!/bin/bash
# $t@$h

echo "Scanning for pyobfgood..."

# Known malicious packages - 11/8/2023
declare -a MALICIOUS_PACKAGES=("Pyobftoexe"
                               "Pyobfusfile"
                               "Pyobfexecute"
                               "Pyobfpremium"
                               "Pyobflight"
                               "Pyobfadvance"
                               "Pyobfuse"
                              )

# Scan and remove malicious packages
echo "Scanning Python packages..."
FOUND_MALICIOUS=false
for pkg in "${MALICIOUS_PACKAGES[@]}"; do
    if pip freeze | grep -q "$pkg"; then
        echo "THREAT FOUND!!! Removing $pkg..."
        pip uninstall -y "$pkg"
        FOUND_MALICIOUS=true
    fi
done
$FOUND_MALICIOUS || echo "No malicious packages found."

# Monitoring Network Activity for suspicious connections
echo "Monitoring network activity for potential shenanigans..."
echo "Threat connections known:"
echo "hxxps[:]//transfer[.]sh/get/wDK3Q8WOA9/start[.]py"
echo "hxxps[:]//www[.]nirsoft[.]net/utils/webcamimagesave.zip"
MALICIOUS_SERVER1="transfer.sh" # Check entire domain just in case
MALICIOUS_SERVER2="nirsoft.net" # Same here
if ! command ss &> /dev/null; then
    echo "netstat command not found. Skipping network activity check."
else
    ss -tupn | grep -E "$MALICIOUS_SERVER1|$MALICIOUS_SERVER2" &&
               echo "Potential threat connection found!!!!" ||
               echo "No suspicious connections found."
fi

# Monitor CPU activity for suspicious computation
echo "Monitoring CPU activity for potential shenanigans..."
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head

# Monitor VIPs to see if they've been modified recently
echo "Checking modifications in VIP directories..."
MODIFIED_FILES=$(sudo find /etc /bin /sbin /usr/bin /usr/sbin -mtime -2)
if [ -n "$MODIFIED_FILES" ]; then
    echo "Recent modifications found in VIP directories:"
    for file in $MODIFIED_FILES; do
        if [ -f "$file" ]; then
            echo "Modified file: $file"
            stat $file
            # If auditd installed and configured, you get more details
            # example:  sudo ausearch -f $file
        fi
    done
else
    echo "No recent modifications in VIP directories."
fi

echo "Pyobfgood scan complete."
