#!/bin/bash

####################################################
# GRIM REPO ########################################
####################################################
# dialogs.sh
#
# contains functionality for showing dialogues
# and reacting on them (strictly console)
#
####################################################

####
# Shows a dialog in which it is only possible to sync
# a file one way or another -- this is the case if we
# have a conflicting binary file
#
# $1 - the file in question
# $2 - 
# $3 -
# $4 - 
function sync_only {
	file=$1;
	#echo sync only $file;
	#present a menu
	echo "--------------------------------------------------------------------";
	echo -e "Binary file \033[1m$file\033[0m is in conflict";
	echo "--------------------------------------------------------------------";
	printf "1) Syncronize from server (use copy from server)\n"
	printf "2) Syncronize from this computer (keep copy from this computer)\n";
	read -s -n1 choice;
	#continue to query untill user inputs a, b or c
	while [[ "$choice" =~ [^12] ]]; do
		read -s -n1 choice;
	done; 
	#if user chooses 1: syncronize from server
	if [ $choice == "1" ]; then 
		echo "Copying $file from server to this computer";
		#remove the serverroot part:
		#echo rsync -vrlpts $GR_SERVER:"$GR_SERVERROOT$file" "$GR_LOCALROOT$file"
		rsync -vrlpts $GR_SERVER:"$GR_SERVERROOT$file" "$GR_LOCALROOT$file"
	fi
	#if user chooses 2: synchronize from client
	if [ $choice == "2" ]; then 
		echo "Copying $file from this computer to server.";
		#echo rsync -vrlpts "$GR_LOCALROOT$file" $GR_SERVER:"$GR_SERVERROOT$file"
		rsync -vrlpts "$GR_LOCALROOT$file" $GR_SERVER:"$GR_SERVERROOT$file"
	fi
}


####
# Should be called in case a conflict occurs between two
# files. It checks whether the file is a text or binary 
# file. If it is a binary file, the choice will be given
# to sync it one way or the other. If it is a text file
# the user will be presented with a merge-program, and 
# the result will be propagated to both server and client
#
# $1 - the filename (that is, next entry)
# $2 - 
function solve_conflict {
	#fix parameters to make sence
	file=$1;
	#if there is a conflict file exists on both server
	#and client, so we can safely check client file.
        
	#TEXT: file is not binary if file command ends with empty
	#or text
	if file "$GR_LOCALROOT$file" | grep -q -P "(empty|text)$"; then 
		solve_txt_conflict "$file"; 
	else
	#BINARY: no merging possible, either sync from server
	#or client, depending on user choice:
		sync_only "$file"
	fi;
}

####
# Handles a conflict between to text files. This is done
# by copying file from server to tmp, and then editing local
# and tmpfile with vimdiff, making the local (nontmp) file
# write protected. After editing, user is queried on whether
# he wants to use the new version of the file. If yes, the 
# local and server version is overwritten with the tmp file.
# 
# $1 - the conflicting filename
# $2 - 
function solve_txt_conflict {
	file=$1;
	#copy version from server to tmp file
	tmpfile=`mktemp`;
	#copy serverversion to tmpfile
	eval rsync -sv $GR_SERVER:"$GR_SERVERROOT$file" "$tmpfile";
	#warn user:
	echo "--------------------------------------------------------------------"; 
	echo "Conflict with text file: $file"
	echo "--------------------------------------------------------------------"; 
	read -s -n1 choice;
	#start vimdiff (-d) making files read only (-c) except for 
	#first buffer (:set noro) which is the tmpfile
	vim -d -R -c ":set noro" $tmpfile "$GR_LOCALROOT$file";
	#confirm changes with user
	echo "--------------------------------------------------------------------"; 
	echo "Do you want too propagate changes made to server and local computer";      
	echo "--------------------------------------------------------------------";
	printf "1) Propagate changes to server and local computer\n"
	printf "2) Cancel and quit\n"
	#continue to query untill user inputs 1 or 2
	read -s -n1 choice;
	while [[ "$choice" =~ [^12] ]]; do
		read -s -n1 choice;   
	done;                
	#if user decides to propagate changes, do it:
	if [ $choice == "1" ]; then
		#copy to server:
		rsync -s $tmpfile $GR_SERVER:"$GR_SERVERROOT$file";
		#overwrite local copy
		cp $tmpfile "$GR_LOCALROOT$file";
	else
		#user choose cancel and quit
		exit 75;
	fi;	
}
