#!/bin/bash
# author: $t@$h
# This script disarms vulnerable log4j on Solr plugin installations that typically come with
# older Omeka classic systems. Was developed for and tested in the wild on 7.7.3 for a customer.

set -euo pipefail

SOLR_HOME="/opt/solr-7.7.3" # Can change this based on installation version but script may not apply
CORE_LIB="$SOLR_HOME/server/lib/ext"
EXPORTER_LIB="$SOLR_HOME/contrib/prometheus-exporter/lib"
JARS=("log4j-core-2.11.0.jar")

# Function to remove JndiLookup.class and back things up
clean_jar() {
  local jar="$1"
  local path_dir="$2"
  [ ! -f "$path_dir/$jar" ] && return 1

  if unzip -l "$path_dir/$jar" |
     grep -q "org/apache/logging/log4j/core/lookup/JndiLookup.class"; then

    echo "Backing up and sanitizing: $jar"
    cp "$path_dir/$jar" "$path_dir/$jar.bak"

    zip -q -d "$path_dir/$jar" \
      "org/apache/logging/log4j/core/lookup/JndiLookup.class"

    return 0
  else
    echo "Already sanitized: $jar"
    return 1
  fi
}

# Remove JndiLookup.class from jars
for lib in "$CORE_LIB" "$EXPORTER_LIB"; do
  for j in "${JARS[@]}"; do
    clean_jar "$j" "$lib"
  done
done

# Disable Log4j2 logging configs
for cfg in /var/solr/log4j2.xml \
  "$SOLR_HOME/server/resources/log4j2.xml" \
  "$SOLR_HOME/server/resources/log4j2-console.xml" \
  /root/solr/log4j2.xml; do

  if [ -f "$cfg" ] && ! grep -q '<Root level="OFF"/>' "$cfg"; then
    echo "Disabling logging in $cfg"
    sed -i 's|^<Configuration.*|<Configuration status="OFF">|' "$cfg"
    sed -i '/<Root.*level=/c\<Root level="OFF"/>' "$cfg"
  fi
done

# Add JVM flags for runtime protection
SYSCTL_FLAG="-Dlog4j2.formatMsgNoLookups=true"
SKIP_JARS_FLAG="-Dlog4j.skipJars=true"
CONFIG_NULL_FLAG="-Dlog4j.configurationFile=file:/dev/null"
DISABLE_JMX_FLAG="-Dlog4j2.disable.jmx=true"

PROFILE="$SOLR_HOME/bin/solr.in.sh"

if ! grep -q "formatMsgNoLookups" "$PROFILE"; then
  echo "Adding JVM flags to $PROFILE"
  sed -i "/SOLR_OPTS=\"/ s|\"$| $SYSCTL_FLAG $SKIP_JARS_FLAG $CONFIG_NULL_FLAG $DISABLE_JMX_FLAG\"|" "$PROFILE"
else
  echo "JVM flags already present in $PROFILE"
fi

echo "Solr hardened against CVE‑2021‑44228"
