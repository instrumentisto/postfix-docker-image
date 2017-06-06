#!/bin/sh

set -e


# Applying Postfix main.cf drop-in files.
# http://www.postfix.org/postconf.5.html
for file in /etc/postfix/main.cf.d/*.cf; do
  [ -f "$file" ] || continue
  while read line; do
    # All valid Postfix main.cf options start with a lower case letter.
    if (printf "%s" "$line" | grep -qE '^[a-z]'); then
      postconf -e "$line"
    fi
  done < "$file"
done


# Applying Postfix master.cf drop-in files.
# http://www.postfix.org/master.5.html
for file in /etc/postfix/master.cf.d/*.cf; do
  [ -f "$file" ] || continue
  printf "\n\n#\n# %s\n#\n" "$file" >> /etc/postfix/master.cf
  cat "$file" >> /etc/postfix/master.cf
done
