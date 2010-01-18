#!/bin/bash

####################################################
# GRIM REPO ########################################
####################################################
# repo_init.sh
#
# Initializes a new repository.
# When initializing a new repository, everything is
# conflicting. That is, the user has to consider all
# the cases of whether to syncronize on way or the 
# other and manually resolve files that are conflicting
#
####################################################

if [ -f ~/.grimreporc ]; then
	source ~/.grimreporc
else
	source `pwd`/.grimreporc
fi

#use pure text menus
source $GR_PATH/text_ui/gr_textmenus.sh
source $GR_PATH/file_info.sh
source $GR_PATH/sync_functions.sh
source $GR_PATH/repo_bookkeeper.sh


####
##
## stupid global
sql_wrapper_rm_flag="-i";
##
while getopts ":hd" opt; do
	case $opt in
		d)
		log 1 "-d was triggered"
		sql_wrapper_rm_flag=""
		;;
		\?)
		log 1 "Invalid option: -$OPTARG"
		exit 1
		;;
		h)
		echo "$0  [-d ] delete sqlite db without asking "
		exit 0
	esac
done



#run list rsync changes from server to local
#using head and tail to avoid the garbage info from rsync
s_to_c=`rsync -vrc -n $GR_SERVER:$GR_SERVERROOT $GR_LOCALROOT | tail --lines=+2 | head --lines=-3`
c_to_s=`rsync -vrc -n $GR_LOCALROOT $GR_SERVER:$GR_SERVERROOT | tail --lines=+2 | head --lines=-3`

####
# Implements the action used if a file only exists
# on server and not locally. This is done by presenting
# user with a menu, and handling his choice.
#
# $1 - file: the conflicting file
# $2 - serverroot: the root of the server (in the form user@server:serverpath/)
# $3 - localroot: the root of the client (eg. /root/to/local/repo/)
function file_exists_server {
	file=$1;
	serverroot=$2;
	localroot=$3;
	log 0 "localroot $localroot";
	#present conflict to user (choice saved in $?)
	file_exists_server_menu "$file"
	choice=$?;
	#if user chooses "cancel", we quit
	if [ $choice -eq "0" ]; then
		exit 73;
	fi;

	#if user chooses to copy:
	if [ $choice -eq "1" ]; then
		copy_data "$file" "$serverroot" "$localroot";
	else 
		if [ $choice -eq "3" ]; then
			#if user wants to view file info:
			
			echo print_remote_file_info "$serverroot" "$file";
			print_remote_file_info "$serverroot" "$file";
			#after showing info, go back to menu
			file_exists_server "$file" "$serverroot" "$localroot";
			return $?;
		else 
			#user chooses to delete -- confirm first:
			confirm_menu "Do you really want to delete file: \033[1m$file\033[0m from server";
			confirmed=$?;
			#if user regrets, give him new prompt on what to do
			if [ $confirmed -eq "0" ]; then
				file_exists_server "$file" "$serverroot" "$localroot";
				return $?;
			else
				delete_data "$file" "$serverroot"
			fi; #end if user prompted on certain to delete
		fi; #end if view/delete file
	fi; #end if user chooses copy or delete
}

####
# Implements the action used if a directory only exists
# on server and not locally. This is done by presenting
# user with a menu, and handling his choice.
#
# $1 - dir: the conflicting dir
# $2 - serverroot: the root of the server (in the form user@server:serverpath/)
# $3 - localroot: the root of the local (eg. /root/to/local/repo/)
function dir_exists_server {
	dir=$1;
	serverroot=$2;
	localroot=$3;

	#present conflict to user (choice saved in $?)
	dir_exists_server_menu "$dir"
	choice=$?;
	#if user chooses "cancel", we quit
	if [ $choice -eq "0" ]; then
		exit 74;
	fi;

	#if user chooses to copy:
	if [ $choice -eq "1" ]; then
		copy_data "$dir" "$serverroot" "$localroot"; 
	else #user chooses to delete -- confirm first:
		confirm_menu "Do you really want to delete directory: \033[1m$dir\033[0m from server";
		confirmed=$?;
		#if user regrets, give him new prompt on what to do
		if [ $confirmed -eq "0" ]; then
			dir_exists_server "$dir" "$serverroot" "$localroot";
			return $?;
		else
			delete_data "$dir" "$serverroot";
		fi; #end if user prompted on certain to delete
	fi; #end if user chooses copy or delete
	#if we made it this far, user has either copied or deleted
	#since its a dir, and copying/deleting is recursive, we can remove
}

####
# Implements the action used if a file only exists
# on locally and not on server. This is done by presenting
# user with a menu, and handling his choice.
#
# $1 - file: the conflicting file
# $2 - serverroot: the root of the server (in the form user@server:serverpath/)
# $3 - localroot: the root of the client (eg. /root/to/local/repo/)
function file_exists_local {
	file=$1;
	serverroot=$2;
	localroot=$3;
	echo localroot $localroot;
	#present conflict to user (choice saved in $?)
	file_exists_local_menu "$file"
	choice=$?;
	#if user chooses "cancel", we quit
	if [ $choice -eq "0" ]; then
		exit 73;
	fi;

	#if user chooses to copy:
	if [ $choice -eq "1" ]; then
		copy_data "$file" "$localroot" "$serverroot";
	else 
		if [ $choice -eq "3" ]; then
			#if user wants to view file info:
			
			echo print_local_file_info "$file" "$localroot";
			print_local_file_info "$file" "$localroot";
			#after showing info, go back to menu
			file_exists_local "$file" "$serverroot" "$localroot";
			return $?;
		else 
			#user chooses to delete -- confirm first:
			confirm_menu "Do you really want to delete file: \033[1m$file\033[0m from this computer";
			confirmed=$?;
			#if user regrets, give him new prompt on what to do
			if [ $confirmed -eq "0" ]; then
				file_exists_local "$file" "$serverroot" "$localroot";
				return $?;
			else
				delete_data "$file" "$localroot"
			fi; #end if user prompted on certain to delete
		fi; #end if view/delete file
	fi; #end if user chooses copy or delete
}

####
# Implements the action used if a directory only exists
# on local repository and not on server. This is done by presenting
# user with a menu, and handling his choice.
#
# $1 - dir: the conflicting dir
# $2 - serverroot: the root of the server (in the form user@server:serverpath/)
# $3 - localroot: the root of the local (eg. /root/to/local/repo/)
function dir_exists_local {
	dir=$1;
	serverroot=$2;
	localroot=$3;

	#present conflict to user (choice saved in $?)
	dir_exists_local_menu "$dir"
	choice=$?;
	#if user chooses "cancel", we quit
	if [ $choice -eq "0" ]; then
		exit 74;
	fi;

	#if user chooses to copy:
	if [ $choice -eq "1" ]; then
		copy_data "$dir" "$localroot" "$serverroot"; 
	else #user chooses to delete -- confirm first:
		confirm_menu "Do you really want to delete directory: \033[1m$dir\033[0m from local repository";
		confirmed=$?;
		#if user regrets, give him new prompt on what to do
		if [ $confirmed -eq "0" ]; then
			dir_exists_local "$dir";
			return $?;
		else
			delete_data "$dir" "$localroot";
		fi; #end if user prompted on certain to delete
	fi; #end if user chooses copy or delete
	#if we made it this far, user has either copied or deleted
	#since its a dir, and copying/deleting is recursive, we can remove
}

##############
# First consider the files that are conflicting from server to local
##############
#save localroot and serverroot short path (rootdir/ instead of /home/user/rootdir/)
#server_root=`echo $GR_SERVERROOT | sed 's#^.*/\(.\)#\1#'i`
#local_root=`echo $GR_LOCALROOT | sed 's#^.*/\(.\)#\1#'i`
#while we still have more conflicts to consider
server_root=$GR_SERVER:$GR_SERVERROOT;
local_root=$GR_LOCALROOT;
alt_conflict_list=$c_to_s;
conflict_list=$s_to_c;

while [ `echo $conflict_list | wc -w` != 0 ]; do
	log 0 "`tree *root`";
	echo "Conflict List: $conflict_list"; 
	#take first line from list of conflicts:
	conflict=`echo "$conflict_list" | head -n 1`
	#then remove that line from c_to_s
	conflict_list=`echo "$conflict_list" | tail --lines=+2`;
    	echo "next conflict=$conflict";

	#if it is a directory (which can be identified by the trailing '/')
	#it means the dir only exists on server and not on locally
	if echo $conflict | grep -q -P '/$'; then
		dir_exists_server "$conflict" "$server_root" "$local_root";
		#since user must either delete or copy (recursively) the
		#we can delete all conflicting entries that are subfiles or
		#subfolders
		conflict_list=`echo "$conflict_list" | grep -P -v "^$conflict"`;
	else
		#it is a file.
		#check if file exists both locally and on server
		#this is the case if $conflict is in $alt_conflict_list
		if echo "$alt_conflict_list" | grep -q $conflict; then
			echo "CONFLICT: $conflict exists in both";
			solve_conflict "$conflict" "$server_root" "$local_root";
			#remove $next_entry from opposite list (that is alt_conflict_list)
			alt_conflict_list=`echo "$alt_conflict_list" | grep -P -v "^$conflict$"`;	
			#echo "RESOLVED: $alt_conflict_list";
		else 
			#file exists only on server
			file_exists_server "$conflict" "$server_root" "$local_root";
		fi;
	fi;
	
done;

#echo "=====================================================================================";
#then consider the files that are conflicting from local to server (s_to_c):
while [ `echo $alt_conflict_list | wc -w` != 0 ]; do
	log 0 "`tree *root`";
	echo "Conflict List: $alt_conflict_list"; 
	#take first line from list of conflicts:
	conflict=`echo "$alt_conflict_list" | head -n 1`
	#then remove that line from c_to_s
	alt_conflict_list=`echo "$alt_conflict_list" | tail --lines=+2`;
    	echo "next conflict=$conflict";

	#if it is a directory (which can be identified by the trailing '/')
	#it means the dir only exists on server and not on locally
	if echo $conflict | grep -q -P '/$'; then
		dir_exists_local "$conflict" "$server_root" "$local_root"
		#since user must either delete or copy (recursively) the
		#we can delete all conflicting entries that are subfiles or
		#subfolders
		alt_conflict_list=`echo "$alt_conflict_list" | grep -P -v "^$conflict"`;
	else
		#it is a file.
		#we resolved all cases where file exists both locally and on server
		#in the other conflict list
		#file exists only on local repository
		file_exists_local "$conflict" "$server_root" "$local_root";
	fi;
done;

#After all conflicts are solved, we clear the database,
recalculate_all "$GR_LOCALROOT";
#tree $GR_LOCALROOT $GR_SERVERROOT
#echo $GR_LOCALROOT
