#!/bin/bash

####################################################
# GRIM REPO ########################################
####################################################
# repo_auto_sync.sh
#
# Program that checks what needs to be synchronized
# and does the actual synchronization
#
####################################################

. sync_functions.sh
. repo_bookkeeper.sh

if [ -f ~/.grimreporc ]; then
source ~/.grimreporc
else
source `pwd`/.grimreporc
fi

#get lists of changes using rsync
#use head and tail to avoid the garbage info from rsync
#s_to_c: what is listed here exists on server, but is either not on, or in a different version on
#client
server_conflicts=`rsync -vrc -n $GR_SERVER:$GR_SERVERROOT $GR_LOCALROOT | tail --lines=+2 | head --lines=-3`
#client_conflicts: What is listed here exists on local, but is either not on, or in a different version on
#server
client_conflicts=`rsync -vrc -n $GR_LOCALROOT $GR_SERVER:$GR_SERVERROOT | tail --lines=+2 | head --lines=-3`

#C_TO_S:
while [ `echo $client_conflicts | wc -w` != 0 ]; do
	tree *root;

	echo Conflict List: $client_conflicts; 
	#take first line from list of conflicts:
	conflict=`echo "$client_conflicts" | head -n 1`
	#then remove that line from client_conflicts
	client_conflicts=`echo "$client_conflicts" | tail --lines=+2`;
    	echo "next conflict=$conflict";

	#if it is a directory (which can be identified by the trailing '/')
	if echo $conflict | grep -q -P '/$'; then
		#echo "CONFLICT DIR: $GR_LOCALROOT$conflict";
		#it means the dir only exists on local and not on server
		#if dir did NOT exist on last sync, it must have been created on local machine
		file_existed "$GR_LOCALROOT$conflict";
		existed=$?
		#echo "returned $existed";
		if [[ $existed == "0" ]]; then 
			echo "$conflict HAS BEEN CREATED LOCALLY";
			#dir must have been created on local machine
			#TODO: copy dir to server.
			#TODO: Delete all sub-entries with dir from client_conflicts
#		dir_exists_server "$conflict" "$server_root" "$local_root";
#		#since user must either delete or copy (recursively) the
#		#we can delete all conflicting entries that are subfiles or
#		#subfolders
#		client_conflicts=`echo "$client_conflicts" | grep -P -v "^$conflict"`;
		else
			#echo "dir existed on last sync"
			#dir must have been deleted on server
			has_changed_locally "$GR_LOCALROOT$conflict"; 
			changed=$?
			if [[ $changed == "1" ]]; then
				#dir deleted on server, but has been changed locally
				echo "DELETED ON SERVER BUT CHANGED LOCALLY";
				#TODO: solve CONFLICT
			else
				echo "DELETED ON SERVER, UNCHANGED LOCALLY - DELETE FROM LOCAL";
				#else dir deleted on server and unchanged locally
				#TODO delete dir locally
			fi; 
		fi;
	else #it is a file
		#if file conflicts on both lists, it means it exists, but have been 
		#changed one or both places
		if echo "$server_conflicts" | grep -q $conflict; then
			#file exists in both places
			#check if file has changed
			has_changed_locally "$GR_LOCALROOT$conflict";
			changed=$?;
			if [[ $changed == "1" ]]; then
				#file changed locally
				has_file_changed_remotely "$GR_LOCALROOT$conflict" "$GR_SERVER" "$GR_SERVERROOT$conflict";
				remote_changed=$?;
				if [[ $remote_changed == "1" ]]; then
					#file also changed on server
					#TODO: resolve CONFLICT
					echo "FILE CHANGED BOTH LOCALLY AND REMOTELY -- CONFLICT"
					#TODO: delete entry from s_to_c after resolved conflict
				else #file only changed locally only
					echo "FILE CHANGED LOCALLY ONLY -- COPY TO SERVER";
					#TODO: copy to server
					#TODO: delete entry from s_to_c
				fi;
			else #file unchanged locally
				#implied from the diff that it must be changed on server then
				#TODO: copy from server to local
				#TODO: delete entry from s_to_c
				echo "FILE CHANGED ON SERVER -- COPY TO LOCAL";
			fi;
		else #file exists on local, not on server
			#check if file existed on last sync
			file_existed "$GR_LOCALROOT$conflict";
			existed=$?
			#echo "returned $existed";
			if [[ $existed == "0" ]]; then
				#file did not exist on last sync, must have been created locally
				#TODO: sync to server
				echo "FILE CREATED LOCALLY -- CPY TO SERVER";
			else #file deleted on server
				#check if it has changed locally
				has_changed_locally "$GR_LOCALROOT$conflict";
				changed=$?;
				if [[ $changed == "1" ]]; then
					#file deleted on server, but modified locally
					#TODO: solve CONFLICT
					echo "FILE DELETED ON SERVER BUT MODIFIED LOCALLY -- CONFLICT";
				else #file deleted on server, untouched locally
					echo "FILE DELETED ON SERVER -- DELETE LOCALLY";
					#TODO: delete locally
				fi;
			fi;
		fi;
	fi; #checking for dir vs file;
done; #end of loop through conflicts



while [ `echo $server_conflicts | wc -w` != 0 ]; do
	tree *root;

	echo Conflict List: $server_conflicts; 
	#take first line from list of conflicts:
	conflict=`echo "$server_conflicts" | head -n 1`
	#then remove that line from server_conflicts
	server_conflicts=`echo "$server_conflicts" | tail --lines=+2`;
    	echo "next conflict=$conflict";

	#if it is a directory (which can be identified by the trailing '/')
	if echo $conflict | grep -q -P '/$'; then
		#it means the dir only exists on server and not on client
		#if dir did NOT exist on last sync, it must have been created on server
		file_existed "$GR_LOCALROOT$conflict";
		existed=$?
		#echo "returned $existed";
		if [[ $existed == "0" ]]; then 
			echo "$conflict HAS BEEN CREATED ON SERVER";
			#dir must have been created on server
			#TODO: copy dir to local.
			#TODO: Delete all sub-entries with dir from server_conflicts
		else #file existed on last sync
			#dir must have been deleted on remote
			has_dir_changed_remotely "$server_conflicts" "$GR_SERVER" "$GR_SERVERROOT" "$conflict" "$GR_LOCALROOT";
			changed=$?
			if [[ $changed == "1" ]]; then
				#dir deleted on server, but has been changed locally
				echo "DELETED ON LOCAL BUT CHANGED ON SERVER";
				#TODO: solve CONFLICT
			else
				echo "DELETED ON LOCAL, UNCHANGED ON SERVER - DELETE FROM LOCAL";
				#else dir deleted on server and unchanged locally
				#TODO delete dir locally
			fi; 
		fi;
	else #it is a file
		#REACHED THIS POINT IN CODING... BELOW IS A COPY FROM client_conflicts LIST, WITH SOME MINOR MINOR CHANGES IN
		exit 0;
		#if file conflicts on both lists, it means it exists, but have been 
		#changed one or both places
		if echo "$server_conflicts" | grep -q $conflict; then
			#file exists in both places
			#check if file has changed
			has_changed_locally "$GR_LOCALROOT$conflict";
			changed=$?;
			if [[ $changed == "1" ]]; then
				#file changed locally
				has_changed_remotely "$GR_LOCALROOT$conflict" "$GR_SERVER" "$GR_SERVERROOT$conflict";
				remote_changed=$?;
				if [[ $remote_changed == "1" ]]; then
					#file also changed on server
					#TODO: resolve CONFLICT
					echo "FILE CHANGED BOTH LOCALLY AND REMOTELY -- CONFLICT"
					#TODO: delete entry from s_to_c after resolved conflict
				else #file only changed locally only
					echo "FILE CHANGED LOCALLY ONLY -- COPY TO SERVER";
					#TODO: copy to server
					#TODO: delete entry from s_to_c
				fi;
			else #file unchanged locally
				#implied from the diff that it must be changed on server then
				#TODO: copy from server to local
				#TODO: delete entry from s_to_c
				echo "FILE CHANGED ON SERVER -- COPY TO LOCAL";
			fi;
		else #file exists on local, not on server
			#check if file existed on last sync
			file_existed "$GR_LOCALROOT$conflict";
			existed=$?
			#echo "returned $existed";
			if [[ $existed == "0" ]]; then
				#file did not exist on last sync, must have been created locally
				#TODO: sync to server
				echo "FILE CREATED LOCALLY -- CPY TO SERVER";
			else #file deleted on server
				#check if it has changed locally
				has_changed_locally "$GR_LOCALROOT$conflict";
				changed=$?;
				if [[ $changed == "1" ]]; then
					#file deleted on server, but modified locally
					#TODO: solve CONFLICT
					echo "FILE DELETED ON SERVER BUT MODIFIED LOCALLY -- CONFLICT";
				else #file deleted on server, untouched locally
					echo "FILE DELETED ON SERVER -- DELETE LOCALLY";
					#TODO: delete locally
				fi;
			fi;
		fi;
	fi; #checking for dir vs file;
done; #end of loop through conflicts


