#!/bin/sh

set -e


# Create all required queue directories for Postfix.
# This is required on container start when Postfix queue directory
# (/var/spool/postfix by default) represents an empty volume.
dataDir=$(postconf | grep 'data_directory = ' | cut -d= -f2 | tr -d "\n ")
mkdir -p "$dataDir"
postfix post-install create-missing
