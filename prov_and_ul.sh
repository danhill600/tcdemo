#!/bin/bash
#a bash script to provision uses based on a csv with the columns
#name,login,user

#where name is both first and last name seperated by a space
#login is the email address for the user
#and user is the current user's onprem /home dir

#box users:create --bulk-file-path=./chi_employees.csv
#
#initialize associations csv ...
rm associations.csv > /dev/null 2>&1

filelength=$(wc -l < chi_employees.csv | xargs)
let filelength--
count=0
while IFS=, read -r name login user; do
  #adjust the < to <= dependingo on if csv has a final newline or not
  #and the > to >= depending on whether you've got a header row.
  if (( "$count" > 0 )) && (( "$count" < "$filelength")); then
  #only need this line if we have the MS-style line ending in the csv provided
    user=${user%?}

    echo "Creating user" "$name" "with email" "$login"
    userid=$(box users:create --id-only "$name" "$login") 
    echo "new User ID is" "$userid"

    #echo "creating casefolders folder.."
    #folderid=$(box folders:create --id-only 260014558897 casefolders_$userid)

    echo "collaboration created with collab ID $collabid."
    echo "uploading contents of local casefolder dirs.."
   # find ../home2/"$user"/casefolders -type d -maxdepth 1 -mindepth 1 -execdir box folders:upload --id-only -p $folderid {} >> associations.csv ';'
    cd ../home2/$user/casefolders
    for i in $(ls); do
      #we're putting these in the FOM for the casesso we can axx this in SF later
      casefolderid=$(box folders:upload --id-only -p 260014558897  ./$i)
      echo "collaborating" "$name" "on $i.."
      collabid=$(box folders:collaborations:add $casefolderid --role=editor --user-id=$userid --id-only)
      echo $i,$casefolderid >> /Users/dhill/tcdemo/associations.csv
    done
    cd - > /dev/null 2>&1
  fi
  let count++

done < ./chi_employees.csv

#writing apex script to associate individual casefolders with SF records..
rm associations.apex > /dev/null 2>&1
echo "box.Toolkit boxToolkit = new box.Toolkit();" > associations.apex

newcount=0
while IFS=, read -r caseID boxfolder; do

    echo "List<Case> myCases$newcount = new List<Case>();" >> associations.apex
    echo "myCases$newcount = [SELECT Case_ID__c FROM Case WHERE Case_ID__c = '$caseID'];" >> associations.apex
    echo "for (Case i : myCases$newcount){" >> associations.apex
    echo "Id SFId = i.id;" >> associations.apex
    echo "string newboxID = '$boxfolder';" >> associations.apex
    echo "box__FRUP__c myNewFrup = boxToolkit.createFolderAssociation(SFId,newboxID);" >> associations.apex
    echo "system.debug('newly created frup id is:' + myNewFrup);" >> associations.apex
    echo "}" >> associations.apex
    let newcount++

done < ./associations.csv

echo "boxToolkit.commitChanges();" >> associations.apex

echo "associations.apex written. paste into SF dev console to create associations"
