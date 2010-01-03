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
. text_ui/text_menus.sh

if [ -f ~/.grimreporc ]; then
	source ~/.grimreporc
else
	source `pwd`/.grimreporc
fi

####
# Implements the action used if a directory has been deleted
# on server, but changed locally. This is done by presenting
# user with a menu, and handling his choice.
#
# $1 - dir: the conflicting dir
# $2 - serverroot: the root of the server (in the form user@server:serverpath/)
# $3 - localroot: the root of the local (eg. /root/to/local/repo/)
function solve_dir_deleted_but_changed_locally {
	local dir=$1;
	local serverroot=$2;
	local localroot=$3;

	#present conflict to user (choice saved in $?)
	dir_deleted_but_changed_locally_menu "$dir"
	local choice=$?;
	#if user chooses "cancel", we quit
	if [ $choice -eq "0" ]; then
		exit 76;
	fi;

	#if user chooses to copy:
	if [ $choice -eq "1" ]; then
		copy_data "$dir" "$localroot" "$serverroot"; 
		#update database
		calculate_dir "$localroot$dir"
	else #user chooses to delete -- confirm first:
		confirm_menu "Do you really want to delete the modified directory: \033[1m$dir\033[0m from local machine";
		local confirmed=$?;
		#if user regrets, give him new prompt on what to do
		if [ $confirmed -eq "0" ]; then
			solve_dir_deleted_but_changed_locally "$dir" "$serverroot" "$localroot";
			return $?;
		else
			delete_data "$dir" "$localroot";
			#update database accordingly
			delete_dir_entry "$localroot$dir"
		fi; #end if user prompted on certain to delete
	fi; #end if user chooses copy or delete
}

####
# Implements the action used if a directory has been deleted
# on local machine, but changed on server. This is done by presenting
# user with a menu, and handling his choice.
#
# $1 - dir: the conflicting dir
# $2 - serverroot: the root of the server (in the form user@server:serverpath/)
# $3 - localroot: the root of the local (eg. /root/to/local/repo/)
function solve_dir_deleted_but_changed_on_server {
	local dir=$1;
	local serverroot=$2;
	local localroot=$3;

	#present conflict to user (choice saved in $?)
	dir_deleted_but_changed_on_server_menu "$dir"
	local choice=$?;
	#if user chooses "cancel", we quit
	if [ $choice -eq "0" ]; then
		exit 77;
	fi;

	#if user chooses to copy:
	if [ $choice -eq "1" ]; then
		copy_data "$dir" "$serverroot" "$localroot"; 
		#update database
		calculate_dir "$localroot$dir"
	else #user chooses to delete -- confirm first:
		confirm_menu "Do you really want to delete the modified directory: \033[1m$dir\033[0m from server";
		local confirmed=$?;
		#if user regrets, give him new prompt on what to do
		if [ $confirmed -eq "0" ]; then
			solve_dir_deleted_but_changed_on_server "$dir" "$serverroot" "$localroot";
			return $?;
		else
			delete_data "$dir" "$serverroot";
			#update database accordingly
			delete_dir_entry "$localroot$dir"
		fi; #end if user prompted on certain to delete
	fi; #end if user chooses copy or delete
}

####
# Implements the action used if a file has been deleted from server
# but changed locally. This is done by presenting
# user with a menu, and handling his choice.
#
# $1 - file: the conflicting file
# $2 - serverroot: the root of the server (in the form user@server:serverpath/)
# $3 - localroot: the root of the local (eg. /root/to/local/repo/)
function solve_file_deleted_but_changed_locally {
	local file=$1;
	local serverroot=$2;
	local localroot=$3;
	
	#present conflict to user (choice saved in $?)
	file_deleted_but_changed_locally_menu "$file"
	local choice=$?;
	#if user chooses "cancel", we quit
	if [ $choice -eq "0" ]; then
		exit 78;
	fi;

	#if user chooses to copy:
	if [ $choice -eq "1" ]; then
		copy_data "$file" "$localroot" "$serverroot"; 
		#update database
		calculate_file "$localroot$file"
	else #user choosfes to delete -- confirm first:
		if [ $choice -eq "3" ]; then
			#if user wants to view file info:
			
			echo print_local_file_info "$file" "$localroot";
			print_local_file_info "$file" "$localroot";
			#after showing info, go back to menu
			solve_file_deleted_but_changed_locally "$file" "$serverroot" "$localroot";
			return $?;
		else 	
			confirm_menu "Do you really want to delete the modified file: \033[1m$file\033[0m from local machine";
			local confirmed=$?;
			#if user regrets, give him new prompt on what to do
			if [ $confirmed -eq "0" ]; then
				solve_file_deleted_but_changed_locally "$file" "$serverroot" "$localroot";
				return $?;
			else
				delete_data "$file" "$localroot";
				#update database accordingly
				delete_file_entry "$localroot$file"
			fi;
		fi; #end if user prompted on certain to delete
	fi; #end if user chooses copy or delete
}

####
# Implements the action used if a file has been deleted from local machine
# but changed on server. This is done by presenting
# user with a menu, and handling his choice.
#
# $1 - file: the conflicting file
# $2 - serverroot: the root of the server (in the form user@server:serverpath/)
# $3 - localroot: the root of the local (eg. /root/to/local/repo/)
function solve_file_deleted_but_changed_on_server {
	local file=$1;
	local serverroot=$2;
	local localroot=$3;
	
	#present conflict to user (choice saved in $?)
	file_deleted_but_changed_on_server_menu "$file"
	local choice=$?;
	#if user chooses "cancel", we quit
	if [ $choice -eq "0" ]; then
		exit 79;
	fi;

	#if user chooses to copy:
	if [ $choice -eq "1" ]; then
		copy_data "$file" "$serverroot" "$localroot"; 
		#update database
		calculate_file "$localroot$file"
	else #user choosfes to delete -- confirm first:
		if [ $choice -eq "3" ]; then
			#if user wants to view file info:
			
			echo print_remote_file_info "$serverroot" "$file";
			print_remote_file_info "$serverroot" "$file";
			#after showing info, go back to menu
			solve_file_deleted_but_changed_on_server "$file" "$serverroot" "$localroot";
			return $?;
		else 
			confirm_menu "Do you really want to delete the modified file: \033[1m$file\033[0m from server";
			local confirmed=$?;
			#if user regrets, give him new prompt on what to do
			if [ $confirmed -eq "0" ]; then
				solve_file_deleted_but_changed_on_server "$file" "$serverroot" "$localroot";
				return $?;
			else
				delete_data "$file" "$serverroot";
				#update database accordingly
				delete_file_entry "$localroot$file"
			fi; #end if user prompted on certain to delete
		fi; 
	fi; #end if user chooses copy or delete
}

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
				#give user the choice between copying or delete
				solve_dir_deleted_but_changed_locally "$conflict" "$GR_SERVER:$GR_SERVERROOT" "$GR_LOCALROOT"
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
					echo "$conflict: FILE CHANGED BOTH LOCALLY AND REMOTELY -- CONFLICT"
					solve_conflict "$conflict" "$GR_SERVER:$GR_SERVERROOT" "$GR_LOCALROOT"
					#either a merging or copying of files has taken place
					#in any case we can update database
					calculate_file "$GR_LOCALROOT$conflict"
					echo calculate_file "$GR_LOCALROOT" "$conflict"
					#delete entry from server_conflicts after resolved conflict
					server_conflicts=`echo "$server_conflicts" | grep -P -v "^$conflict\$"`;
					echo echo "$server_conflicts" | grep -P -v "^$conflict\$";
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
					echo "$conflict: FILE DELETED ON SERVER BUT MODIFIED LOCALLY -- CONFLICT";
					#file deleted on server, but modified locally
					 solve_file_deleted_but_changed_locally "$conflict" "$GR_SERVER:$GR_SERVERROOT" "$GR_LOCALROOT";
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
				solve_dir_deleted_but_changed_on_server "$conflict" "$GR_SERVER:$GR_SERVERROOT" "$GR_LOCALROOT";
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
				echo "$conflict: FILE DELETED ON LOCALLY BUT MODIFIED ON SERVER -- CONFLICT";
			 	solve_file_deleted_but_changed_on_server  "$conflict" "$GR_SERVER:$GR_SERVERROOT" "$GR_LOCALROOT";
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


