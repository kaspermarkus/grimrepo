#!/bin/bash 
####################################################
# GRIM REPO ########################################
####################################################
# checksum_wrapper.sh
#
# Wraps the checksum functionality for files and dirs.
# The checksum for a while should change whenever the
# content of the file changes.
# For starters, this is done via the md5sum tool.
# For directories, this is very inefficiently done
# by taking the md5sum of the md5sum+filename of
# all the files found (recursively) in the directory.
#
####################################################


####
# calc_checksum
#
# Calculates the checksum of the argument whether its a
# file or dir
#
# $1 - the path to the file
function calc_checksum {
	filepath=$1;

	if [ -f "$localroot$filepath" ]; then 
		checksum=`calc_file_checksum "$1"`;
	else 
		checksum=`calc_dir_checksum "$1"`;
	fi;
	echo "${checksum%  *}"
}

####
# calc_remote_file_checksum
#
# Calculates the checksum of the remote file, given as
# argument. Argument must be a file
#
# $1 - serverinfo: remote host (eg. user@host.com)
# $2 - file: full path to file
function calc_remote_file_checksum {
	serverinfo=$1;
	file=$2;

	 checksum=`ssh $serverinfo "md5sum \"$file\""`;
	 echo "${checksum%  *}";
}

####
# Calculates checksum for dir
#
# $1 - path to dir, including dirname
function calc_dir_checksum {
	find "$1" -type f -exec md5sum {} \; | md5sum;
}

####
# Calculates checksum for file 
#
# $1 - path to file , including fileame
function calc_file_checksum {
	md5sum "$1";	
}
