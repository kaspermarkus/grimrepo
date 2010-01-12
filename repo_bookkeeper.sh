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
	checksum=`get_checksum "$file"`;
	echo "cheksum is: $checksum" 1>&2; 
	if [[ "$checksum" != "" ]]; then 
		#echo "1";
		return 1;
	else
		echo "0";
		return 0;
	fi; 
}

####
# has_changed_locally
#
# A simple function for checking whether a file or
# dir has changed locally since last sync. Echoes (and returns)
# 1 if it has and 0 if not.
#
# $1 - file: the file to check
function has_changed_locally {
	file=$1;
	#echo calc_checksum "$file";
	#echo get_checksum "$file";
	#check new checksum vs. old checksum
	if [[ `calc_checksum "$file"` != `get_checksum "$file"` ]]; then
		#has changed:
		#echo "1";
		return 1;
	else 
		#echo "0"
		return 0
	fi; 
}

####
# has_changed_remotely
#
# A simple function for checking whether a file or
# dir has changed on server since last sync. Echoes (and returns)
# 1 if it has and 0 if not.
#
# $1 - localfile: the file to check (incl. filename)
# $2 - serverinfo: the server
# $3 - remotefile: the path (incl. filename) to remote file
function has_file_changed_remotely {
	localfile=$1;
	serverinfo=$2;
	remotefile=$3;
	#echo calc_remote_file_checksum "$serverinfo" "$remotefile"
	#echo get_checksum "$localfile"
	#check new checksum vs. old checksum
	if [[ `calc_remote_file_checksum "$serverinfo" "$remotefile"` != `get_checksum "$localfile"` ]]; then
		#has changed:
		#echo "1";
		return 1;
	else 
		echo "0"
		return 0
	fi; 
}

###
# has_dir_changed_remotely
#
# runs through entries from server_conflict
# that involves it, and check if they have
# changed since last time. Used when a dir
# has been locally removed 
#
# $1 - $server_conflicts
# $2 - $serverinfo
# $3 - $serverroot
# $4 - $dir (dir relative to serverroot)
# $5 - $localroot
function has_dir_changed_remotely {
	local server_conflicts=$1;
	local serverinfo=$2;
	local serverroot=$3;
	local dir=$4;
	local localroot=$5;

	echo "SERVERROOTdir: $dir on full list: $server_conflicts";
	#for each file from serverconflicts that is 
	#inside dir and is a file (does not end with)
	local relevant_conflicts=`echo "$server_conflicts" | grep "^$dir" | grep -v -P '/$'`;

	#loop through them
	while [ `echo $relevant_conflicts | wc -w` != 0 ]; do
		#take first line from list of conflicts:
		local conflict=`echo "$relevant_conflicts" | head -n 1`
		#then remove that line from client_conflicts
		relevant_conflicts=`echo "$relevant_conflicts" | tail --lines=+2`;
		echo "next conflict=$conflict";
		
		#for each, do a checksum check with remote file vs. checksums
		has_file_changed_remotely "$localroot$conflict" "$serverinfo" "$serverroot$conflict";
		local changed=$?;
		#if even a single file has changed, we consider dir changed
		if [[ $changed == "1" ]]; then
			return 1;
		fi;
	done;
	#if no file has changed, we reach this point, and return 0o
	return 0;
}


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
		if [ -d $file ]; then 
			#if dir, make sure we have trailing slash
			file=`echo "$file" | sed 's#\([^/]\)$#\1/#'`; 
		fi;
		echo FILE "$file";
		checksum=`calc_checksum "$file"`;
		set_checksum "$file" "$checksum";
		IFS=$(echo -en "\n\b")
	done;
	IFS=$SAVEIFS;
}

####
# calculate_file 
#
# Calculates the md5 sums of the file
# and enters data into the database
#
# $1 - path to file inklusive filename
function calculate_file {
	file=$1;
	#calculate checksum
	checksum=`calc_checksum "$file"`;
	set_checksum "$file" "$checksum";
}

 
