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
. sql_wrapper.sh

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

	#echo Conflict List: $client_conflicts; 
	#take first line from list of conflicts:
	conflict=`echo "$client_conflicts" | head -n 1`
	#then remove that line from client_conflicts
	client_conflicts=`echo "$client_conflicts" | tail --lines=+2`;
    	#echo "next conflict=$conflict";

	#if it is a directory (which can be identified by the trailing '/')
	if echo $conflict | grep -q -P '/$'; then
		#it means the dir only exists on local and not on server
		#if dir did NOT exist on last sync, it must have been created on local machine
		file_existed "$GR_LOCALROOT$conflict";
		existed=$?
		#echo "returned $existed";
		if [[ $existed == "0" ]]; then 
			echo "$conflict HAS BEEN CREATED LOCALLY";
			#dir must have been created on local machine, copy to server
			copy_data "$conflict" "$GR_LOCALROOT" "$GR_SERVER:$GR_SERVERROOT";
			#update database with the new dir
		 	calculate_dir "$GR_LOCALROOT$conflict";	
		else
			#echo "dir existed on last sync"
			#dir must have been deleted on server
			has_changed_locally "$GR_LOCALROOT$conflict"; 
			changed=$?
			if [[ $changed == "1" ]]; then
				#dir deleted on server, but has been changed locally
				echo "$conflict: DELETED ON SERVER BUT CHANGED LOCALLY";
				#TODO: solve CONFLICT
			else
				echo "$conflict: DELETED ON SERVER, UNCHANGED LOCALLY - DELETE FROM LOCAL";
				#else dir deleted on server and unchanged locally
				delete_data "$conflict" "$GR_LOCALROOT"
				#update database
				delete_dir_entry "$GR_LOCALROOT$conflict";
			fi; 
		fi;
		#Delete all sub-entries with dir from client_conflicts, since we solved all
		#conflicts with those by either copy, delete or manually
		client_conflicts=`echo "$client_conflicts" | grep -P -v "^$conflict"`;
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
					echo "$conflict: FILE CHANGED BOTH LOCALLY AND REMOTELY -- CONFLICT"
					#TODO: delete entry from server_conflicts after resolved conflict
				else #file only changed locally only
					echo "$conflict: FILE CHANGED LOCALLY ONLY -- COPY TO SERVER";
					#copy file to server
					copy_data "$conflict" "$GR_LOCALROOT" "$GR_SERVER:$GR_SERVERROOT"
					#delete entry from server_conflicts, since conflict is solved
					server_conflicts=`echo "$server_conflicts" | grep -P -v "^$conflict\$"`;
					#update database accordingly
					calculate_file "$GR_LOCALROOT$conflict";
				fi;
			else #file unchanged locally
				echo "$conflict: FILE CHANGED ON SERVER -- COPY TO LOCAL";
				#implied from the diff that it must be changed on server then
				#copy from server to local
				copy_data "$conflict" "$GR_SERVER:$GR_SERVERROOT" "$GR_LOCALROOT"
				#delete entry from server_conflicts, since conflict is solved
				server_conflicts=`echo "$server_conflicts" | grep -P -v "^$conflict\$"`;

				#update database accordingly
				calculate_file "$GR_LOCALROOT$conflict"
			fi;
		else #file exists on local, not on server
			#check if file existed on last sync
			file_existed "$GR_LOCALROOT$conflict";
			existed=$?
			#echo "returned $existed";
			if [[ $existed == "0" ]]; then
				echo "$conflict: FILE CREATED LOCALLY -- CPY TO SERVER";
				#file did not exist on last sync, must have been created locally
				#copy to server
				copy_data "$conflict" "$GR_LOCALROOT" "$GR_SERVER:$GR_SERVERROOT";
				#update database with the new dir
		 		calculate_file "$GR_LOCALROOT$conflict";	
			else #file deleted on server
				#check if it has changed locally
				has_changed_locally "$GR_LOCALROOT$conflict";
				changed=$?;
				if [[ $changed == "1" ]]; then
					#file deleted on server, but modified locally
					#TODO: solve CONFLICT
					echo "$conflict: FILE DELETED ON SERVER BUT MODIFIED LOCALLY -- CONFLICT";
				else #file deleted on server, untouched locally
					echo "$conflict: FILE DELETED ON SERVER -- DELETE LOCALLY";
					#else dir deleted on server and unchanged locally
					delete_data "$conflict" "$GR_LOCALROOT"
					#update database
					delete_file_entry "$GR_LOCALROOT$conflict";
				fi;
			fi;
		fi;
	fi; #checking for dir vs file;
done; #end of loop through conflicts



while [ `echo $server_conflicts | wc -w` != 0 ]; do
	tree *root;

	echo Server Conflict List: $server_conflicts; 
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
			#dir must have been created on server, copy to local
			copy_data "$conflict" "$GR_SERVER:$GR_SERVERROOT" "$GR_LOCALROOT";
			#update database with the new dir
			calculate_dir "$GR_LOCALROOT$conflict"; 
		else #file existed on last sync
			#dir must have been deleted on remote
			has_dir_changed_remotely "$server_conflicts" "$GR_SERVER" "$GR_SERVERROOT" "$conflict" "$GR_LOCALROOT";
			changed=$?
			if [[ $changed == "1" ]]; then
				#dir deleted on server, but has been changed locally
				echo "$conflict: DELETED ON LOCAL BUT CHANGED ON SERVER";
				#TODO: solve CONFLICT
			else
				echo "$conflict: DELETED ON LOCAL, UNCHANGED ON SERVER - DELETE FROM SERVER";
				#else dir deleted on local machine and unchanged server
				#delete the data from server also
				delete_data "$conflict" "$GR_SERVER:$GR_SERVERROOT"
				#update database
				delete_dir_entry "$GR_LOCALROOT$conflict";
			fi; 
		fi;
		#Delete all sub-entries with dir from server_conflicts, since we solved all
		#conflicts with those by either copy, delete or manually
		server_conflicts=`echo "$server_conflicts" | grep -P -v "^$conflict"`;

	else #it is a file
		#file exists on server and not locally
		#check if file existed on last sync
		file_existed "$GR_LOCALROOT$conflict";
		existed=$?
		#echo "returned $existed";
		if [[ $existed == "0" ]]; then
			#file did not exist on last sync, must have been created on server 
			echo "$conflict: FILE CREATED ON SERVER -- CPY TO LOCAL";
			#copy to local
			copy_data "$conflict" "$GR_SERVER:$GR_SERVERROOT" "$GR_LOCALROOT";
			#update database with the new dir
			calculate_file "$GR_LOCALROOT$conflict";
		else #file deleted on server
			#check if it has changed locally
			has_file_changed_remotely "$GR_LOCALROOT$conflict" "$GR_SERVER" "$GR_SERVERROOT$conflict";
			changed=$?;
			if [[ $changed == "1" ]]; then
				#file deleted on local, but modified on server
				#TODO: solve CONFLICT
				echo "$conflict: FILE DELETED ON LOCALLY BUT MODIFIED ON SERVER -- CONFLICT";
			else #file deleted on on local machine, untouched on server
				#else file deleted on local machine and unchanged on server
				echo "$conflict: FILE DELETED LOCALLY -- DELETE FROM SERVER";
				#delete the file from server
				delete_data "$conflict" "$GR_SERVER:$GR_SERVERROOT"
				#update database
				delete_file_entry "$GR_LOCALROOT$conflict";
			fi;
		fi;
	fi; #checking for dir vs file;
done; #end of loop through conflicts


