#!/bin/bash

cd "$(dirname ${BASH_SOURCE[0]})"
TMPSCRIPT=$(mktemp)
uids=`cat /etc/passwd | cut -d: -f3|sort -n | tr '\n' ',' | sed 's/.$//'`
echo "uids=[$uids]" > $TMPSCRIPT

cat iptablemaker.py >> $TMPSCRIPT
python $TMPSCRIPT
rm $TMPSCRIPT

