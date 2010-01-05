
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

