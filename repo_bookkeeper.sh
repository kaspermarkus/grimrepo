#!/bin/bash

####################################################
# GRIM REPO ########################################
####################################################
# repo_bookkeeper.sh
#
# Wrapper for database and checksum generation. 
# This should be the only program talking to checksum_wrapper
# and sql_wrapper.
####################################################

source sql_wrapper.sh
source checksum_wrapper.sh

####
# file_exists
#
# A simple function for checking whether a file or
# dir exists in the databse. Echoes (and returns)
# 1 if it exists and 0 if not.
#
# $1 - file: the file to check
function file_existed {
	file=$1;
		
	if [ get_checksum "$file" != "" ]; then 
		echo "1";
		return 1;
	else
		echo "0";
		return 0;
	fi; 
}

####
# has_changed
#
# A simple function for checking whether a file or
# dir has changed since last sync. Echoes (and returns)
# 1 if it has and 0 if not.
#
# $1 - file: the file to check
function has_changed {
	#check new checksum vs. old checksum
	if [ calc_checksum "$file" != get_checksum "$file" ]; then
		#has changed:
		echo "1";
		return 1;
	else 
		echo "0"
		return 0
	fi; 
}

####
# get_checksum
# $1 - file: the file to check
# $2 - local_root: the local root
####
# set_checksum
# $1 - file: the file to check
# $2 - checksum: the new checksum
####
# delete_entry
# $1 - file: the file to check

####
# recalculate_all
#
# Recalculates all the md5 sums in the repository,
# clears the database, and inserts the new values
#
# $1 - path: the base directory to calculate from
function recalculate_all {
	path=$1;
	#clear the database
	clear_database;
	#recursively, calculate and insert all md5-sums
	calculate_dir "$path";
}

####
# calculate_dir
#
# Calculates the md5 sums of the entire dir recursivesy
# and enters data into the database
#
# $1 - path to dir inklusive dirname
function calculate_dir {
	path=$1;
	#go through reculive list of files and dirs
	SAVEIFS=$IFS
	IFS=$(echo -en "\n\b")
	for file in `find $path`; do
		#for each entry
		IFS=$SAFEIFS;
		echo FILE "$file";
		checksum=`calc_checksum "$file"`;
		set_checksum "$file" "$checksum";
		IFS=$(echo -en "\n\b")
	done;
	IFS=$SAVEIFS;
}
