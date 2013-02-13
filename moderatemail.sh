#!/bin/bash
#MODERATOR="viking@vikingcycles.com"
DOMAIN="surekid.com"
FILE=`uuidgen | cut -c25-`
cat > /tmp/$FILE
#TO=`cat /tmp/$FILE | formail -x To -z|cut -d@ -f1`
TO=`cat /tmp/$FILE | formail -u Received -x Received | tail -n 1 |tr ',;<>()"\47 ' '[\n*]' | sed -n -e '/@/p' | cut -d@ -f1 | tr -cd "[:alnum:]"`
MODERATOR=`grep $TO /tmp/moderators | cut -d: -f2`
ID=`cat /tmp/$FILE | formail -c -X Subject | cut -d "[" -f2|cut -c8-20 |tr -cd "[:alnum:]"`
#echo $TO $MODERATOR $ID $FILE
#exit 0
if [ -f /tmp/$ID ]; then
	TO=`cat /tmp/$ID | formail -u Received -x Received | tail -n 1 |tr ',;<>()"\47 ' '[\n*]' | sed -n -e '/@/p' | cut -d@ -f1 | tr -cd "[:alnum:]"`
	MODERATOR=`grep $TO /tmp/moderators | cut -d: -f2`
	cat /tmp/$ID |formail -a "X-surekid-approved-by: $MODERATOR"  | sendmail $TO
	rm /tmp/$ID;
	rm /tmp/$FILE;
	exit 0;
fi
#echo OK
#printenv >>/tmp/$FILE
#echo id is $ID >>/tmp/$FILE
SUBJ=`cat /tmp/$FILE | formail -x subject`
#echo $SUBJ
cat /tmp/$FILE | formail -I "Subject: [SUREKID $FILE $TO] $SUBJ"|formail -I "Reply-to: approve-this-message@$DOMAIN" | sendmail $MODERATOR
#rm /tmp/$FILE

