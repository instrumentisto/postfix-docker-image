#!/bin/sh

set -e


# Applying Postfix main.cf drop-in .cf files.
# http://www.postfix.org/postconf.5.html
for file in /etc/postfix/main.cf.d/*.cf; do
  [ -f "$file" ] || continue
  printf "\n\n#\n# %s\n#\n" "$file" >> /etc/postfix/main.cf
  cat "$file" >> /etc/postfix/main.cf
done


# Applying Postfix master.cf drop-in .cf files.
# http://www.postfix.org/master.5.html
for file in /etc/postfix/master.cf.d/*.cf; do
  [ -f "$file" ] || continue
  printf "\n\n#\n# %s\n#\n" "$file" >> /etc/postfix/master.cf
  cat "$file" >> /etc/postfix/master.cf
done

# Applying Postfix master.cf drop-in .postconf files.
# http://www.postfix.org/postconf.1.html
for file in /etc/postfix/master.cf.d/*.postconf; do
  [ -f "$file" ] || continue
  while read line; do
    # All valid master.cf postconf instructions start with one of: -M, -F, -P.
    if (printf "%s" "$line" | grep -qE '^-[MFP] '); then
      postconf "$line"
    fi
  done < "$file"
done