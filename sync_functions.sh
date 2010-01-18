#!/bin/bash

####################################################
# GRIM REPO ########################################
####################################################
# sync_functions.sh
#
# Contains functionality for copying/syncing data to
# and from the server, as well as deleting data from
# either. 
#
####################################################

source $GR_PATH/general_functions.sh
source $GR_PATH/file_info.sh

####
# This function is to be used when a file or directory
# exists on server and not on local, or the other way
# around. It recursively copies the file from client
# to server, or vice versa, depending on parameters.
#
# $1 - file in question
# $2 - from (if remote, use entire user@server:root syntax)
# $3 - to (if remote, use entire user@server:root syntax)
function copy_data {
	file=$1;
	from=$2;
	to=$3;

	echo rsync -vrlpts "$from$file" "$to$file";
	res=`rsync -vrlpts "$from$file" "$to$file"`;
	if [ $? -ne 0 ]; then 
		return 53;
	fi;		
	echo "returned $res";
}

####
# This function is to be used when a file or directory
# exists on server and not on local, or the other way
# around. It deletes the file/dir in question.
#
# $1 - file in question
# $2 - root (if remote, use entire user@server:root syntax)
function delete_data {
	file=$1;
	root=$2;

	#check if we are trying to delete something remote
	is_remote "$root$file"; 
	returned=$?
	if [ $returned -eq "1" ]; then 
		#get the path part of the ssh/path syntax
		serverroot=`echo "$root" | sed s#^[^:]*:##`
		#and then get the login/server part for the ssh statement
		serverinfo=`echo "$root" | sed "s#:$serverroot\\\$##"`
		#now delete stuff from server via ssh:
		log 1 "ssh $serverinfo \"rm -rf '$serverroot$file'\"";
		eval ssh $serverinfo "rm -rf \"$serverroot$file\"";
	else 
		rm -rf "$root$file";
	fi;
	
	if [ $returned -ne 0 ]; then 
		return 63;
	fi;		
}

