#!/bin/sh
#####################################################################################################################################
#  Script Name       : FindJobsByFileName.sh                                                                                        #
#  created by        : Siva Nadesan                                                                                                 #
#  created date      : 26-Aug-2015                                                                                                  #
#  Syntax            : FindJobsByFileName.sh <ENVIRONMENT> <JOBTYPE> <LOGTYPE>                                                      #
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
  echo "Syntax : " $ScriptNameWithExt "<ENVIRONMENT> <JOBTYPE> <LOGTYPE>"
  exit;
fi

ENVIRONMENT=$1
JOBTYPE=$2
LOGTYPE=$3

# Create lower case, upper case, camel case version of input
ENVIRONMENT_UC=$(echo $ENVIRONMENT | tr '[:lower:]' '[:upper:]')
ENVIRONMENT_LC=$(echo $ENVIRONMENT | tr '[:upper:]' '[:lower:]')
ENVIRONMENT_CC=$(echo "$(tr '[:lower:]' '[:upper:]' <<< ${ENVIRONMENT:0:1})${ENVIRONMENT:1}")

JOBTYPE_UC=$(echo $JOBTYPE | tr '[:lower:]' '[:upper:]')
JOBTYPE_LC=$(echo $JOBTYPE | tr '[:upper:]' '[:lower:]')
JOBTYPE_CC=$(echo "$(tr '[:lower:]' '[:upper:]' <<< ${JOBTYPE:0:1})${JOBTYPE:1}")

LOGTYPE_UC=$(echo $LOGTYPE | tr '[:lower:]' '[:upper:]')
LOGTYPE_LC=$(echo $LOGTYPE | tr '[:upper:]' '[:lower:]')
LOGTYPE_CC=$(echo "$(tr '[:lower:]' '[:upper:]' <<< ${LOGTYPE:0:1})${LOGTYPE:1}")

# Default types, used for compares
DEFAULT_LOGTYPE=$(echo "ALL" | tr '[:lower:]' '[:upper:]')
DEFAULT_JOBTYPE=$(echo "ALL" | tr '[:lower:]' '[:upper:]')

# Log the inputs 
echo ENVIRONMENT_UC = $ENVIRONMENT_UC
echo ENVIRONMENT_LC = $ENVIRONMENT_LC
echo ENVIRONMENT_CC = $ENVIRONMENT_CC

echo JOBTYPE_UC = $JOBTYPE_UC
echo JOBTYPE_LC = $JOBTYPE_LC
echo JOBTYPE_CC = $JOBTYPE_CC

echo LOGTYPE_UC = $LOGTYPE_UC
echo LOGTYPE_LC = $LOGTYPE_LC
echo LOGTYPE_CC = $LOGTYPE_CC

echo DEFAULT_LOGTYPE = $DEFAULT_LOGTYPE
echo DEFAULT_JOBTYPE = $DEFAULT_JOBTYPE

#######################################################################################################
# Location of log files                                                                               #
#######################################################################################################

#LOGDIR=$(echo $THISDIR"/logs" | tr '[:upper:]' '[:lower:]')
LOGDIR=$(echo $THISDIR"/logs")

#TEMPDIR=$(echo $THISDIR"/temp" | tr '[:upper:]' '[:lower:]')
TEMPDIR=$(echo $THISDIR"/temp")

#INPUTDIR=$(echo $THISDIR"/input" | tr '[:upper:]' '[:lower:]')
INPUTDIR=$(echo $THISDIR"/input")

echo LOGDIR = $LOGDIR
echo TEMPDIR = $TEMPDIR
echo INPUTDIR = $INPUTDIR

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

LOGFILE=$LOGDIR"/"$SCRIPT_NAME"_"$ENVIRONMENT_UC"_"$CURR_DATE".log"
PROJECT_FILE=$INPUTDIR"/ProjectName.txt"
TEMPFILE1=$TEMPDIR"/"$SCRIPT_NAME"_"$ENVIRONMENT_UC"_alljobslisting.dat"
TEMPFILE2=$TEMPDIR"/"$SCRIPT_NAME"_"$ENVIRONMENT_UC"_afterjobtypefilter.dat"
TEMPFILE3=$TEMPDIR"/"$SCRIPT_NAME"_"$ENVIRONMENT_UC"_logeventlisting.dat"

echo PROJECT_FILE = $PROJECT_FILE

#######################################################################################################
# Delete previous tmp file                                                                            #
#######################################################################################################

rm $PROJECT_FILE > $PROJECT_FILE
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

# List of all projects in a given server and Limit the same to a given environment
dsjob -lprojects | grep $ENVIRONMENT_UC  																>>$PROJECT_FILE

# List all jobs in a given project
while read project_name
do
	 echo "===========================================================================" 				>>$LOGFILE
     echo `date "+%Y-%m-%d%H:%M:%S"` "- Listing the jobs in project : " $project_name 					>>$LOGFILE
	 echo `date "+%Y-%m-%d%H:%M:%S"` "- Listing the jobs in project : " $project_name
	 
	 # List all jobs in the given project	
	 dsjob -ljobs $project_name |  sed "s/^/$(echo $project_name',')/" 									>>$TEMPFILE1

done < $PROJECT_FILE


# Grep the batch jobs 	

if [ "$JOBTYPE_UC" == "$DEFAULT_JOBTYPE" ]; then
   cp $TEMPFILE1 $TEMPFILE2
else
   grep "Batch::*" $TEMPFILE1 																		    >>$TEMPFILE2
fi

# Read job name and get the log ID and time stamp for all jobs
# get log summary records, grep the records which starts with a number (log event id), cut event id and event time stamp, append the project name and job name
while read datastage_job_list
do

	project_name=$(echo $datastage_job_list | cut -d',' -f 1)
	datastage_job_name=$(echo $datastage_job_list | cut -d',' -f 2)
	
	echo "===========================================================================" 				    >>$LOGFILE
	
	if [ "$LOGTYPE_UC" == "$DEFAULT_LOGTYPE" ]; then
	   echo `date "+%Y-%m-%d%H:%M:%S"` "- Processing job : " dsjob -logsum $project_name $datastage_job_name                                                                       >>$LOGFILE
	   dsjob -logsum $project_name $datastage_job_name | grep ^[0-9] | cut -f1,3 | tr "\\t" "," | sed '/^$/d' |  sed "s/^/$(echo $project_name','$datastage_job_name',')/"  					   >> $TEMPFILE3
	else
	   echo `date "+%Y-%m-%d%H:%M:%S"` "- Processing job : " dsjob -logsum -type $LOGTYPE_UC $project_name $datastage_job_name                                                     >>$LOGFILE
	   dsjob -logsum -type $LOGTYPE_UC $project_name $datastage_job_name | grep ^[0-9] | cut -f1,3 | tr "\\t" "," | sed '/^$/d' |  sed "s/^/$(echo $project_name','$datastage_job_name',')/"     >> $TEMPFILE3
	fi
	
done < $TEMPFILE2

#######################################################################################################
# write trailer log record                                                                            #
#######################################################################################################
echo "===========================================================================" 				    >>$LOGFILE
echo `date "+%Y-%m-%d%H:%M:%S"` "- " $SCRIPT_NAME " finished" >> $LOGFILE

exit 0;
