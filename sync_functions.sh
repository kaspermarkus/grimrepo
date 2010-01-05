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

source general_functions.sh
source file_info.sh
source text_ui/text_menus.sh

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

	res=`rsync -vrlpts "$from$file" "$to$file"`;
	echo rsync -vrlpts "$from$file" "$to$file";
	echo "returned $res";
	if [ $? -ne 0 ]; then 
		return 53;
	fi;		
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
	if [ $? -eq "1" ]; then 
		#get the path part of the ssh/path syntax
		serverroot=`echo "$root" | sed s#^[^:]*:##`
		#and then get the login/server part for the ssh statement
		serverinfo=`echo "$root" | sed "s#:$serverroot\\\$##"`
		#now delete stuff from server via ssh:
		echo ssh $serverinfo "rm -rf \"$serverroot$file\"";
		ssh $serverinfo "rm -rf \"$serverroot$file\"";
	else 
		rm -rf "$root$file";
	fi;
	
	if [ $? -ne 0 ]; then 
		return 63;
	fi;		
}

####
# Should be called in case a conflict occurs between two
# files. It checks whether the file is a text or binary 
# file. If it is a binary file, the choice will be given
# to sync it one way or the other. If it is a text file
# the user will be presented with a merge-program, and 
# the result will be propagated to both server and client
#
# $1 - the filename 
# $2 - server root (in the form user@location:/path/to/file
# $2 - local root 
function solve_conflict {
	#fix parameters to make sence
	file=$1;
	serverroot=$2;
	localroot=$3;

	#if there is a conflict file exists on both server
	#and client, so we can safely check client file.
        
	#TEXT: file is not binary if file command ends with empty
	#or text
	echo file "$localroot$file" pipe grep -q -P "(empty|text)$"; 
	if file "$localroot$file" | grep -q -P "(empty|text)$"; then 
		solve_text_conflict "$file" "$serverroot" "$localroot"
	else
	#BINARY: no merging possible, either sync from server
	#or client, depending on user choice:
		solve_binary_conflict "$file" "$serverroot" "$localroot"
	fi;
}

####
# Solve a conflict between two binary files.
#
# $1 - the file in question
# $2 - serverroot (in the form user@location:/path/to/file 
# $3 - localroot
function solve_binary_conflict {
	file=$1;
	serverroot=$2;
	localroot=$3

	#echo sync only $file;
	#present a menu
	solve_binary_conflict_menu "$file";
	choice=$?;
	#if user chooses "cancel", we quit
	if [ $choice -eq "0" ]; then
		exit 71;
	fi;
	
	#if user chooses to copy from server to client:
	if [ $choice -eq "1" ]; then
		copy_data "$file" "$serverroot" "$localroot"; 
	else 
		if [ $choice -eq "2" ]; then 
			#user chooses to copy from client to server
			copy_data "$file" "$localroot" "$serverroot"; 
		else
			if [ $choice -eq "3" ]; then 
				#usr choose to view local file info;
				print_local_file_info "$file" "$localroot"
				solve_binary_conflict "$file" "$serverroot" "$localroot";
				return $?
			fi;
			if [ $choice -eq "4" ]; then
				#usr chooses to view server file info;
				echo print_remote_file_info "$serverroot" "$file";
				print_remote_file_info "$serverroot" "$file";
				solve_binary_conflict "$file" "$serverroot" "$localroot";
				return $?
			fi;
		fi;
	fi;
}

####
# Handles a conflict between to text files. This is done
# by copying file from server to tmp, and then editing local
# and tmpfile with some program (depending on on UI).
#
# $1 - the conflicting filename
# $2 - serverroot: the serverroot (in the form user@server:/path/to/root/)
# $3 - localroot: the local root 
function solve_text_conflict {
	file=$1;
	serverroot=$2;
	localroot=$3;
	
	#print menu to user:
	solve_text_conflict_menu $file;
	choice=$?;
	
	##if user chooses "cancel", we quit
	if [ $choice -eq "0" ]; then
		exit 72;
	fi;
	
	#if user chooses to copy from server to client:
	if [ $choice -eq "1" ]; then
		copy_data "$file" "$serverroot" "$localroot"; 
	else 
		if [ $choice -eq "2" ]; then 
			#user chooses to copy from client to server
			copy_data "$file" "$localroot" "$serverroot"; 
		else
			if [ $choice -eq "3" ]; then
				merge_text_files "$file" "$serverroot" "$localroot";
			else 
				if [ $choice -eq "4" ]; then 
					#usr choose to view local file info;
					echo print_local_file_info "$file" "$localroot"
					print_local_file_info "$file" "$localroot"
					solve_text_conflict "$file" "$serverroot" "$localroot";
					return $?
				fi;
				if [ $choice -eq "5" ]; then
					#usr chooses to view server file info;
					print_remote_file_info "$serverroot" "$file";
					solve_text_conflict "$file" "$serverroot" "$localroot";
					return $?
				fi;
			fi;
		fi;
	fi;
}

####
# Allows user to merge two conflicting text files. This is done
# by copying file from server to tmp, and then editing local
# and tmpfile with some merging program
# After editing, user is queried on whether
# he wants to use the new version of the file. If yes, the 
# local and server version is overwritten with the tmp file.
# 
# $1 - the conflicting filename
# $2 - serverroot: the serverroot (eg. user@server:/path/to/root)
# $3 - localroot: the localroot
function merge_text_files {
	file=$1;
	serverroot=$2;
	localroot=$3;
	#copy version from server to tmp file
	tmpfile=`mktemp`;
	#copy serverversion to tmpfile
	eval rsync -sv "$serverroot$file" "$tmpfile";
	#warn user:
	warn_text_conflict_menu "$file";
	#give user interface to merge
	ui_merge_files "$file" "$localroot" "$tmpfile"
	#confirm changes with user
	confirm_merge_text_menu
	#if user decides to propagate changes, do it:
	if [ $choice == "1" ]; then
		#copy to server:
		rsync -s "$tmpfile" "$serverroot$file";
		#overwrite local copy
		cp "$tmpfile" "$localroot$file";
	else
		#user choose cancel and quit
		solve_text_conflict "$file" "$serverroot" "$localroot";
	fi;	
}

