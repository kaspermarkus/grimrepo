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
# Prints info on the file given as argument to 
# screen.
#
# $1 - path to file, including filename, relative to local
#       root
# $2 - the local root (repository) of the file
function get_checksum {
	filepath=$1;
	localroot=$2;

	if [ -f "$localroot$filepath" ]; then 
		checksum=`get_file_checksum "$1" "$2"`;
	else 
		checksum=`get_dir_checksum "$1" "$2"`;
	fi;
	echo "${checksum% *}"
}

####
# Calculates checksum for dir
#
# $1 - path to dir, including dirname, relative to local
#       root
# $2 - the local root (repository) of the dir 
function get_dir_checksum {
	find "$2$1" -type f -exec md5sum {} \; | md5sum;
}

####
# Calculates checksum for file 
#
# $1 - path to file , including fileame, relative to localroot
# $2 - the local root (repository) of the file 
function get_file_checksum {
	md5sum "$2$1";	
}
