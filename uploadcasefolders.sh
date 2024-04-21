#!/bin/bash
#a bash script to upload the casefolders of recently provisioned users.
#it operates on upload.csv, which provision.csv will create
#this .csv  contains a userid column and user column with no header.

rm unconfirmed.csv > /dev/null 2>&1
touch unconfirmed.csv > /dev/null 2>&1

filelength=$(wc -l < upload.csv | xargs)
let filelength--
count=0
while IFS=, read -r userid  user; do
  if (( "$count" <= "$filelength")); then 
    if [ "$(box users:get me --as-user=$userid 2>&1 | grep -c user_email_confirmation_required)" -ge 1 ]; then
      echo "$userid" "has not been confirmed sending to uncomfirmed.csv"
      echo "$userid","$user" >> unconfirmed.csv  
    else
      folderid=$(box folders:upload --id-only --as-user="$userid" ../home2/"$user"/casefolders)
      #ls -ld ../home2/"$user"/casefolders
      echo "casefolders belonging to User ID" "$userid" "uploaded to Box as folder ID" "$folderid" 
    fi
  fi
  let count++
done < ./upload.csv 
