#!/bin/sh
#####################################################################################################################################
#  Script Name       : FindJobsByFileName.sh                                                                                        #
#  created by        : Siva Nadesan                                                                                                 #
#  created date      : 26-Aug-2015                                                                                                  #
#  Syntax            : FindJobsByFileName.sh <ENVIRONMENT> <LOG_EVENT_LISTING> <KEYWORD_LISTING>								    #
##################################################################################################################################### 

#######################################################################################################
# Find the location of scripts and check for temp  and logs dir, create if don't exist                #
#######################################################################################################

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -d "$THISDIR/logs" ]; then
   echo "logs directory exists"
else
   mkdir -p "$THISDIR/logs" 2>/dev/null
   chmod 755 "$THISDIR/logs"
fi

if [ -d "$THISDIR/temp" ]; then
   echo "tmp directory exists"
else
   mkdir -p "$THISDIR/temp" 2>/dev/null
   chmod 755 "$THISDIR/temp"
fi

#######################################################################################################
# Find the Script Name automatically                                                                  #
#######################################################################################################

ScriptNameWithExt=`basename "$0"`
extension="${ScriptNameWithExt##*.}"
SCRIPT_NAME="${ScriptNameWithExt%.*}"

echo "SCRIPT_NAME : " $SCRIPT_NAME
#######################################################################################################
# Read Arguments                                                                                      #
#######################################################################################################

echo "Total Input Arguments : " $#

if [ $# -ne 3 ];
then
  echo " "
  echo "Syntax : " $ScriptNameWithExt " <ENVIRONMENT> <LOG_EVENT_LISTING> <KEYWORD_LISTING>"
  exit;
fi

ENVIRONMENT=$1
LOG_EVENT_LISTING=$2
KEYWORD_LISTING=$3

echo ENVIRONMENT = $ENVIRONMENT
echo LOG_EVENT_LISTING = $LOG_EVENT_LISTING
echo KEYWORD_LISTING = $KEYWORD_LISTING

#######################################################################################################
# Location of log files                                                                               #
#######################################################################################################

#LOGDIR=$(echo $THISDIR"/logs" | tr '[:upper:]' '[:lower:]')
LOGDIR=$(echo $THISDIR"/logs")

#TEMPDIR=$(echo $THISDIR"/temp" | tr '[:upper:]' '[:lower:]')
TEMPDIR=$(echo $THISDIR"/temp")

#INPUTDIR=$(echo $THISDIR"/input" | tr '[:upper:]' '[:lower:]')
INPUTDIR=$(echo $THISDIR"/input")

parms1=$TEMPDIR"/"$LOG_EVENT_LISTING
parms2=$INPUTDIR"/"$KEYWORD_LISTING

echo LOGDIR = $LOGDIR
echo TEMPDIR = $TEMPDIR

#export MAILLIST=replace_with_your_email_Address

#######################################################################################################
# Protect files created by this script.                                                               #
#######################################################################################################

umask u=rw,g=rw,o=rw

#######################################################################################################
# Read Current System time stamp                                                                      #
#######################################################################################################

CURR_DATE=`date "+%Y-%m-%d%H:%M:%S"`

#######################################################################################################
# Open up a new log for todays run								      #
#######################################################################################################

LOGFILE=$LOGDIR"/"$SCRIPT_NAME"_"$ENVIRONMENT"_"$CURR_DATE".log"
TEMPFILE1=$TEMPDIR"/"$SCRIPT_NAME"_"$ENVIRONMENT"_detailed_logs.dat"
TEMPFILE2=$TEMPDIR"/"$SCRIPT_NAME"_"$ENVIRONMENT"_match_found.dat"
TEMPFILE3=$TEMPDIR"/"$SCRIPT_NAME"_"$ENVIRONMENT"_tempfile3.dat"

#######################################################################################################
# Delete previous tmp file                                                                            #
#######################################################################################################

rm $TEMPFILE1 > $TEMPFILE1
rm $TEMPFILE2 > $TEMPFILE2
rm $TEMPFILE3 > $TEMPFILE3

#######################################################################################################
# Create and write the log header message                                                             #
#######################################################################################################

echo `date "+%Y-%m-%d%H:%M:%S"` "- " $SCRIPT_NAME " Started" > $LOGFILE

#######################################################################################################
# Insert Seperator                                                                                    #
#######################################################################################################

echo ' ' >>$LOGFILE

#######################################################################################################
# Run Script to List the job logs                                                                     #
#######################################################################################################

cd  `cat /.dshome`
. ./dsenv 
cd bin

# For a given job and event id from above step capture the log details to a temp file

while read job_logsum
do
	 echo "===========================================================================" 	>>$LOGFILE
     echo `date "+%Y-%m-%d%H:%M:%S"` "- Processing Logs for : " $job_logsum 				>>$LOGFILE
	 
	 project_name=$(echo $job_logsum | cut -d',' -f 1)
     datastage_job_name=$(echo $job_logsum | cut -d',' -f 2)
	 event_id=$(echo $job_logsum | cut -d',' -f 3)
	 event_timestamp=$(echo $job_logsum | cut -d',' -f 4)
	 
	 echo "project_name             : " $project_name										>>$LOGFILE
     echo "datastage_job_name       : " $datastage_job_name 								>>$LOGFILE
	 echo "event_id       			: " $event_id			 								>>$LOGFILE
	 echo ' ' 																				>>$LOGFILE
	 
	 dsjob -logdetail $project_name $datastage_job_name $event_id 	| tr "\\n" "," | sed '/^$/d' | sed "s/^/$(echo $project_name','$datastage_job_name','$event_id','$event_timestamp',')/"			>>$TEMPFILE1
	 echo ""																				>>$TEMPFILE1
done < $parms1

# Open the input file with the list of files which needs to be searched and grep for the same in log details file
while read file_name
do
	 echo "===========================================================================" 	>>$LOGFILE
     echo `date "+%Y-%m-%d%H:%M:%S"` "- Search for : " $file_name 							>>$LOGFILE
	 
	 grep $file_name $TEMPFILE1 | sed '/^$/d' | sed "s/^/$(echo $file_name',')/"	>>$TEMPFILE2
	 
done < $parms2

#######################################################################################################
# write trailer log record                                                                            #
#######################################################################################################
echo `date "+%Y-%m-%d%H:%M:%S"` "- " $SCRIPT_NAME " finished" >> $LOGFILE

exit 0;