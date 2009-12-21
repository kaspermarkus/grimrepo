#!/bin/bash

####################################################
# GRIM REPO ########################################
####################################################
# repo_watch.sh
#
# Watches the relevant directories for changes in files
# and writes it to the log files.
#
####################################################

if [ -f ~/.grimreporc ]; then
	source ~/.grimreporc
else
	source `pwd`/.grimreporc
fi

#make sure we have the directory for log files
if [ ! -d $GR_INDEX ]; then
	mkdir $GR_INDEX
fi

#tell that we are starting the repo_watch program 
echo "Starting repo_watch";
md5=`uname -a | md5sum`
#take first word of md5 string
machine=${md5% *}
#monitor file system, print in format:
#time dir file event
inotifywait -mrq --timefmt '%s' --format '%w %f %e %T' \
-e modify,create,delete $GR_LOCALROOT | while read dir file event time; do
	#make a timestamp from seconds. The division by $GR_LOG_TIME
	#ensures that the timestamp will remain the same for 
	#$GR_LOG_TIME seconds
	let timestamp=`date +%s`/$GR_LOG_TIME;
	backupfile=$GR_INDEX/$timestamp.$machine
	#write to the log
	echo $backupfile
	echo "dir: ${dir}, file: ${file}, event: ${event}"
	echo ${dir}${file} ${event} >> $backupfile
done
