#!/bin/sh
#######################################################################################################
#  Script Name       : ClearDS_RTLogRTStatus.sh                                                       #
#  created by        : Siva Nadesan                                                              	  #
#  created date      : 19-May-2015                                                                    # 
#  Syntax            : ClearDS_RTLogRTStatus.sh <PROJECTNAME> <INPUTFILE>                             #
#  Input file format : DATASTAGE_JOB_NAME, PROJECT_NAME                                               #
#  Example           : TestJob01, ENTECHLOG_DEV                                                       #  
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
  echo "Syntax: ClearDS_RTLogRTStatus.sh <PROJECTNAME> <NameOfFileWhichHoldsJobNames>"
  echo " "
  echo "Usage:  Job to clear LOG and STATUS file of a DataStage job"
  exit;
fi

TEMPPROJECTNAME=$1
INPUTFILE=$2

#Convert Project Name to upper case always, Comment out this line if you need the project name to be same 
PROJECTNAME=$(echo $TEMPPROJECTNAME | tr [[:lower:]] [[:upper:]])

echo TEMPPROJECTNAME = $TEMPPROJECTNAME
echo PROJECTNAME = $PROJECTNAME
echo INPUTFILE = $INPUTFILE

FILE_NAME=$(echo $INPUTFILE | cut -d'.' -f1)
echo  FILE_NAME = $FILE_NAME

#######################################################################################################
# Location of log files                                                                               #
#######################################################################################################

#LOGDIR=$(echo $THISDIR"/logs" | tr '[:upper:]' '[:lower:]')

LOGDIR=$(echo $THISDIR"/logs")

#TEMPDIR=$(echo $THISDIR"/temp" | tr '[:upper:]' '[:lower:]')

TEMPDIR=$(echo $THISDIR"/temp")

#INPUTDIR=$(echo $THISDIR"/input" | tr '[:upper:]' '[:lower:]')

INPUTDIR=$(echo $THISDIR"/input")

PROJECTDIR=$(echo "/opt/IBM/InformationServer/Server/Projects/"$PROJECTNAME)

DSHOME=$(echo "/opt/IBM/InformationServer/Server/DSEngine")

ClearDS_RTLogRTStatus_parms=$INPUTDIR"/"$INPUTFILE

echo LOGDIR = $LOGDIR
echo TEMPDIR = $TEMPDIR
echo INPUTDIR = $INPUTDIR
echo PROJECTDIR = $PROJECTDIR
echo DSHOME = $DSHOME
echo ClearDS_RTLogRTStatus_parms = $ClearDS_RTLogRTStatus_parms

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

LOGFILE=$LOGDIR"/"$PROJECTNAME"_"$FILE_NAME"_"$CURR_DATE".log"
TEMPFILE=$TEMPDIR"/"$PROJECTNAME"_"$FILE_NAME".dat"

echo LOGFILE = $LOGFILE
echo TEMPFILE = $TEMPFILE

#######################################################################################################
# Delete previous tmp file                                                                            #
#######################################################################################################

rm $TEMPFILE > $TEMPFILE

#######################################################################################################
# Create and write the log header message                                                             #
#######################################################################################################

echo `date "+%Y-%m-%d%H:%M:%S"` "- ClearDS_RTLogRTStatus.sh Started" > $LOGFILE

#######################################################################################################
# Insert Seperator                                                                                    #
#######################################################################################################

echo ' ' >>$LOGFILE

#######################################################################################################
# Run Script to List the job logs                                                                     #
#######################################################################################################

#source the dsenv file to create DataStage shell environment
. $DSHOME/dsenv

#Change the directory of execution to the location where your project is created
cd $PROJECTDIR

while read job_details
do
     echo `date "+%Y-%m-%d%H:%M:%S"` "- Processing Job log for : " $job_details 	>>$LOGFILE
	 
     datstage_job_name=$(echo $job_details | cut -d',' -f1)	 
     datstage_job_id=$(echo $job_details | cut -d',' -f2)
     
     echo "datstage_job_id          : " $datstage_job_id			    >>$LOGFILE
	 echo "Command to be executed   : $DSHOME/bin/dssh CLEAR.FILE RT_LOG"$datstage_job_id		>>$LOGFILE
	 echo "Command to be executed   : $DSHOME/bin/dssh CLEAR.FILE RT_STATUS"$datstage_job_id		>>$LOGFILE
     echo ' ' >>$LOGFILE
	 
	 $DSHOME/bin/dssh "CLEAR.FILE RT_LOG"$datstage_job_id
	 $DSHOME/bin/dssh "CLEAR.FILE RT_STATUS"$datstage_job_id
		 
     echo "">>$TEMPFILE

done < $ClearDS_RTLogRTStatus_parms

#######################################################################################################
# write trailer log record                                                                            #
#######################################################################################################
echo `date "+%Y-%m-%d%H:%M:%S"` '- ClearDS_RTLogRTStatus.sh finished' >> $LOGFILE

#mailx -s"Job to clear RTLOG and RTSTATUS finished" $MAILLIST < $TEMPDIR/ClearDS_RTLogRTStatus.dat
exit 0;