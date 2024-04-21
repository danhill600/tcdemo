#!/bin/bash
#a bash script to provision uses based on a csv with the columns
#name,login,user

#where name is both first and last name seperated by a space
#login is the email address for the user
#and user is the current user's onprem /home dir

#box users:create --bulk-file-path=./chi_employees.csv

rm upload.csv > /dev/null 2>&1
touch upload.csv > /dev/null 2>&1

filelength=$(wc -l < chi_employees.csv | xargs)
let filelength--
count=0
while IFS=, read -r name login user; do
  if (( "$count" > 0 )) && (( "$count" < "$filelength")); then 
    user=${user%?}
    echo "Creating user" "$name" "with email" "$login" 
    userid=$(box users:create --id-only "$name" "$login") 
    echo "new User ID is" "$userid"
    echo "$userid","$user" >> upload.csv
  fi
  let count++

done < ./chi_employees.csv 
echo "users have been added to upload.csv. Run upload.sh to upload casefolders"
echo "for any users who have set up their password." 
