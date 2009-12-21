#!/bin/bash

####################################################
# GRIM REPO ########################################
####################################################
# repo_auto_sync.sh
#
# Program that checks what needs to be synchronized
# and does the actual synchronization
#
####################################################

. sync_functions.sh

if [ -f ~/.grimreporc ]; then
	source ~/.grimreporc
else
	source `pwd`/.grimreporc
fi

#get lists of changes using rsync
#use head and tail to avoid the garbage info from rsync
#s_to_c: what is listed here exists on server, but is either not on, or in a different version on
#client
s_to_c=`rsync -vrc -n $GR_SERVER:$GR_SERVERROOT $GR_LOCALROOT | tail --lines=+2 | head --lines=-3`
#c_to_s: What is listed here exists on local, but is either not on, or in a different version on
#server
c_to_s=`rsync -vrc -n $GR_LOCALROOT $GR_SERVER:$GR_SERVERROOT | tail --lines=+2 | head --lines=-3`

echo "S_TO_C:"
echo "$s_to_c";
echo "C_TO_S:"
echo "$c_to_s";

#Try to identify what we can do automatically:

#C_TO_S:
#for each line
	#if dir -- dir exists on local not on server:
		#if entry is in one of the log files with mkdir:
			#copy to server.. Delete all sub-entries with dir from c_to_s
		#else
			#must have been deleted on server
			#check if we changed any sub files/dirs by searching log files
			#if (changes subfiles/dirs) {
				#dir deleted on server, but changed locally also, CONFLICT
				#resolve conflict;
			#else (dir deleted on server)
				#delete dir locally 
	#else (it is a file)
		#if file is not in s_to_s
		#(it is a file, exists on local, not on server))
			#if entry is in logfile with CREATE
				#file has been created, sync to server
				#delete entries with file from log+c_to_s
			#if entry is in logfile with MODIFY
				#file has been deleted on server,  but modified locally
				#CONFLICT
			#if entry is NOT in logfile
				#file has been deleted on server
				#delete locally
		#else 
			#file differs from local machine to server
			#TODO: hvordan goer vi lortet automatisk her?


#S_TO_C

#for file in `ls $GR_INDEX` ; do
#	echo checking: "$file"
#	 
#	 while read file event time; do
#		 echo $event $time $file
#		  
#		  case $event in
#		  'CREATE,ISDIR')
#		  echo 'create mode'
#		  from=$GR_LOCALROOT
#		  to=$GR_SERVERROOT
#		  len=${#GR_LOCALROOT}
#		  filepath=${file:len}
#		  copy_data $filepath $from $to
#		  ;;
#		  *)
#		  echo "Unknown event, sorry dude\n"
#		  exit 88;
#		  ;;
#		  esac
#		  done < $GR_INDEX/$file
#		   
##TODO delete the log file   
#done
