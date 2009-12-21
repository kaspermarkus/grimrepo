#!/bin/bash

#sets up a test case for repo_sync and repo_watch
if [ -f ~/.grimreporc ]; then
	source ~/.grimreporc
else 
	source `pwd`/.grimreporc
fi

#make two identical dirs
rm -rf "${GR_LOCALROOT}" "$GR_SERVERROOT"
mkdir -p ${GR_LOCALROOT}{A,B,C}
touch ${GR_LOCALROOT}{A/a1,B/b1,B/b2,C/c1}
cp -r ${GR_LOCALROOT} $GR_SERVERROOT

workingdir=`pwd`;
#start repo watch
#TODO: the following line is not working as it should
./repo_watch.sh & 
#inotifywait -mrq --timefmt '%s' --format '%w %f %e %T' -e modify,create,delete $GR_LOCALROOT &
sleep 2;

#ps aux | grep "repo_watch.sh" | grep "bash\ "
#make directory locally
#echo mkdir ${GR_LOCALROOT}D
mkdir ${GR_LOCALROOT}D
#mkdir ${GR_LOCALROOT}E
#mkdir ${GR_LOCALROOT}F
#echo Done creating dirs

#kill repo watch
#ps aux | grep "repo_watch.sh" | grep "bash\ "
#echo kill `ps aux | grep "repo_watch.sh" | grep "bash\ " | awk {'print $2'} | head -1`
kill -9 `ps aux | grep "repo_watch.sh" | grep "bash\ " | awk {'print $2'} | head -1`
#echo kill `ps aux | grep "repo_watch.sh" | grep "bash\ " | awk {'print $2'} | head -1`
kill -9 `ps aux | grep "repo_watch.sh" | grep "bash\ " | awk {'print $2'} | head -1`
#echo `ps aux | grep "repo_watch.sh" | grep "bash\ "`
