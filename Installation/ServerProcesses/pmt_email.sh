#!/bin/bash
msgfile=/usr/local/bin/pmt_msg.txt
logfile=/var/log/pmt_email.log
path=$1
file=$2
event=$3
# use date format according to your wishes how you want the time and date displayed
# i.e. you can use: datetime=$(date +"%F %T"), I use simply "date"
datetime=$(date)
echo "PMT Data Request for email: ${file%_*} " >> ${logfile}
echo "${datetime} Data file in: " ${path} " Event: " ${event} >> ${logfile}
echo "${datetime} File name: " ${file} >> ${logfile}
MYFILE=${path}/${file}
# recipients email address
# define the address to receive the email
RECP=${file%_*}
# sender's email address
SENDER=sender@example.com
# determine db instance from file name to append appropriate email message
if [[ "$MYFILE" == *bmgf* ]]
then
  echo "This is a BMGF data file." >> ${logfile}
  msgfile=/usr/local/bin/bmgf_msg.txt
fi
if [[ "$MYFILE" == *oam* ]]
then 
  echo "This is a OAM data file." >> ${logfile}
  msgfile=/usr/local/bin/oam_msg.txt
fi

# check to see if the file is still downloading and wait for it to complete before emailing
STARTTIME=$(date +%s)
echo "Start time is: $STARTTIME " >> ${logfile}
while (true)
do
  COUNT1=$(stat -c%s "$MYFILE")
  sleep 10s 
  COUNT2=$(stat -c%s "$MYFILE")
  echo "Count1: $COUNT1  Count2: $COUNT2" >> ${logfile}
  CURRENTTIME=$(date +%s)
  ELAPSEDTIME=$(($CURRENTTIME - $STARTTIME))
  echo "Elapsed time is: $ELAPSEDTIME" >> ${logfile}
  if [ $ELAPSEDTIME -gt 300 ] && [ $COUNT2 == 0 ] 
  then
    echo "The file you have requested is too large, please reduce your data request and try again.(Processing time exceeds 5 minutes)" | mutt -s "Data Request" $RECP
    echo "The file is too large, processing exceeds 5 mintues" >> ${logfile}
    break
  elif [ $COUNT1 != $COUNT2 ] || [ $COUNT2 == 0 ]
  then
    echo "File is still being written, wait..." >> ${logfile}
    sleep 5
  else
    echo "File is ready to be emailed." >> ${logfile}
    #send the contents as HTML and also attachment
    mutt -s "Data Request" $RECP -a $MYFILE < ${msgfile}
    break
  fi
done
echo "------------------------ End ------------------------" >> ${logfile}
rm $MYFILE
