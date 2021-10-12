#!/bin/sh
#######################################################################################################
#  Script Name       : AuditDataStageJobLogs.sh                                                       #
#  created by        : Entechlog                                                                      #
#  created date      : 26-Oct-2014                                                                    # 
#  Syntax            : AuditDataStageJobLogs.sh <ENVIRONMENT> <INPUTFILE>                             #
#  Input file format : SYSTEM_NAME, AUTOSYS_JOB_NAME, DATASTAGE_JOB_NAME, PROJECT_NAME                #
#                    : SYSTEM_NAME & AUTOSYS_JOB_NAME can be skipped by using UNKNOWN                 #
#  Example           : UNKNOWN, UNKNOWN, TestJob01, ENTECHLOG_DEV                                     #  
#######################################################################################################

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
# Read Arguments                                                                                      #
#######################################################################################################

echo "Total arguments.." $#
if [ $# == 0 ];
then
  echo " "
  echo "Syntax: AuditDataStageJobLogs.sh <ENVIRONMENT> <FileNameWithProjectAndJobName>"
  echo " "
  echo "Usage:  Job to pull the status of Datastage job from Datastage Log Files"
  exit;
fi

ENVIRONMENT=$1
INPUTFILE=$2

echo ENVIRONMENT = $ENVIRONMENT
echo INPUTFILE = $INPUTFILE

FILE_NAME=$(echo $INPUTFILE | cut -d'.' -f1)
echo  FILE_NAME = $FILE_NAME

#######################################################################################################
# Location of log files                                                                               #
#######################################################################################################

LOGDIR=$(echo $THISDIR"/logs" | tr '[:upper:]' '[:lower:]')

TEMPDIR=$(echo $THISDIR"/temp" | tr '[:upper:]' '[:lower:]')

INPUTDIR=$(echo $THISDIR"/input" | tr '[:upper:]' '[:lower:]')

AuditDataStageJobLogs_parms=$INPUTDIR"/"$INPUTFILE

echo LOGDIR = $LOGDIR
echo TEMPDIR = $TEMPDIR
echo INPUTDIR = $INPUTDIR
echo AuditDataStageJobLogs_parms = $AuditDataStageJobLogs_parms

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

LOGFILE=$LOGDIR"/"$ENVIRONMENT"_"$FILE_NAME"_"$CURR_DATE".log"
TEMPFILE=$TEMPDIR"/"$ENVIRONMENT"_"$FILE_NAME".dat"

#######################################################################################################
# Delete previous tmp file                                                                            #
#######################################################################################################

rm $TEMPFILE > $TEMPFILE

#######################################################################################################
# Create and write the log header message                                                             #
#######################################################################################################

echo `date "+%Y-%m-%d%H:%M:%S"` "- AuditDataStageJobLogs.sh Started" > $LOGFILE

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

while read job_details
do
     echo `date "+%Y-%m-%d%H:%M:%S"` "- Processing Job log for : " $job_details 	>>$LOGFILE

     system_name=$(echo $job_details | cut -d',' -f1)
     autosys_name=$(echo $job_details | cut -d',' -f2)
     batch_name=$(echo $job_details | cut -d',' -f3)
     project_name_org=$(echo $job_details | cut -d',' -f4)
     project_name=$(echo "${project_name_org/'$ENVIRONMENT'/$ENVIRONMENT}" | tr '[:lower:]' '[:upper:]')
     project_name_batch_name="$project_name $batch_name" 

     echo "system_name              : " $system_name					>>$LOGFILE
     echo "autosys_name	            : " $autosys_name					>>$LOGFILE
     echo "batch_name               : " $batch_name					>>$LOGFILE
     echo "project_name             : " $project_name					>>$LOGFILE
     echo "project_name_batch_name  : " $project_name_batch_name 			>>$LOGFILE
     echo ' ' >>$LOGFILE

     dsjob -logsum -type STARTED -max 2 $project_name_batch_name | tr "\\n" ",">>$TEMPFILE
     echo "">>$TEMPFILE

done < $AuditDataStageJobLogs_parms

#######################################################################################################
# write trailer log record                                                                            #
#######################################################################################################
echo `date "+%Y-%m-%d%H:%M:%S"` '- AuditDataStageJobLogs.sh finished' >> $LOGFILE

#mailx -s"Monthly Job Audit Status" $MAILLIST < $TEMPDIR/AuditDataStageJobLogs.dat
exit 0;