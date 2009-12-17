#!/bin/bash


if [ -f ~/.grimreporc ]; then
	source ~/.grimreporc
else
	source `pwd`/.grimreporc
fi

if [ ! -d $GR_INDEX ]; then
	mkdir $GR_INDEX
fi




last_timestamp=`date +%s`
timer=$GR_LOG_TIME
md5=`uname -a | md5sum`
machine=${md5% *}
backupfile=$GR_INDEX/$last_timestamp.$machine

inotifywait -mrq --timefmt '%s' --format '%T %w %f %e' \
-e modify,create,delete $GR_LOCALROOT | while read time dir file event; do

#we properly need an max-file-change counter as well
if [ $((`date +%s` % $timer )) == "0" ]; then
	#hit our new log
	
	echo $backupfile
	echo  ${file} ${event} ${time} >>  $backupfile
	last_timestamp=`date +%s`
	backupfile=$GR_INDEX/$last_timestamp.$machine
else
	echo $backupfile
	echo  ${file} ${event} ${time} >>  $backupfile
fi
	 done
