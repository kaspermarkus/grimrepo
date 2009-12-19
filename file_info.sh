#!/bin/bash

####################################################
# GRIM REPO ########################################
####################################################
# file_info.sh
#
# Contains functionality for retrieving information 
# on a file, and printing it to screen. The files 
# handles can both be local and remote.
#
####################################################


####
# Prints info on the file given as argument to 
# screen.
#
# $1 - the name of the file
# $2 - the full path to the file, including the filename
# $3 - the placement of the file. This should be something
#      like "locally" or "server" or "192.168.1.1". Does
#      not matter other than for reporting location of file
#      to user
function general_print_file_info {
	filename=$1;
	fullpath=$2;
	placement=$3;

	#print the file info to STD_OUT
	echo "Filename:      $filename";
	echo "Placement:     $placement";
	echo "General Info:  "`file "$fullpath" | sed "s#$fullpath: ##"`;
	echo "File size:     "`du -h "$fullpath" | sed s#\\t.*##`;
	echo "Last modified: "`stat --format="%y" "$fullpath"`
}	

####
# Print the info on the local file to STD_OUT.
#
# $1 - the name of the file
# $2 - full path to the file
function print_local_file_info {
	general_print_file_info "$1" "$1$2" "Local";
}

####
# Prints file info on file from remote server.
# This is done by copying serverfile to a file
# in /tmp folder, then running print_file_info
# on it.
#
# $1 - The server root (in the form: user@server:/path/to/repo) 
# $2 - filename
function print_remote_file_info {
	server=$1;
	file=$2;
	
	#create temporary file
	tmpfile=`mktemp`;
	#copy file from server
	rsync -azs "$server$file" "$tmpfile";
	echo rsync -azs "$server$file" "$tmpfile";
	#then print info
	general_print_file_info "$file" "$tmpfile" "On Server";
}

