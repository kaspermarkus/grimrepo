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

while getopts ":hs:" opt; do
	case $opt in
		s)
		echo "-s was triggered, Parameter: $OPTARG" >&2
		conflictsolution=$OPTARG;
		;;
		\?)
		echo "Invalid option: -$OPTARG" >&2
		exit 1
		;;
		:)
		echo "Option -$OPTARG requires an argument." >&2
		exit 1
		;;
		h)
		echo "$0  [-s solution]"
		exit 0
	esac
done

#do we have any solutions?1
if [ ! -z "$conflictsolution" ]; then

	echo "got solving answer: $conflictsolution" 1>&2;
	solution_filename=`printf "$conflictsolution" 	   | head -n 1 | tail -n 1`
	solution_conflict_type=`printf "$conflictsolution" | head -n 2 | tail -n 1`
	solution_chksumlocal=`printf "$conflictsolution"  	   | head -n 3 | tail -n 1`
	solution_chksumserver=`printf "$conflictsolution" 	   | head -n 4 | tail -n 1`
	solution_action=`printf "$conflictsolution" 	   | head -n 5 | tail -n 1`	

	echo solution_filename $solution_filename 1>&2
	echo solution conflict_type $solution_conflict_type 1>&2
	echo solution_chksumlocal $solution_chksumlocal  1>&2
	echo solution_chksumserver $solution_chksumserver 1>&2
	echo solution_action $solution_action 1>&2



	if [ ! -z $solution_action ]; then
		got_action=true;
		#check for known action types
		case "$solution_action" in
			COPY_TO_SERVER)
			;;
			DELETE_SERVER)
			;;
			COPY_TO_LOCAL)
			;;
			DELETE_LOCAL)
			;;
			*)
			echo "Unknown action: [$solution_action]";
			exit 1
		esac
	fi
fi

#sets the next conflict state
#we only solve one at the time.  
#so if allready set, we exit
function set_conflict_state {
if [ ! -z $returnconflict ]; then
	#if $returnconflict exists and length > 0
	echo 'one conflict already detected, lets solve it first' 1>&2;
	#returnconflict=$1
	#exit 0;
else
	#else set $return conflict
	returnconflict=$1
	#exit 0	
fi

}

#return conflict parameteres to the caller
function get_conflict_state {
	echo -e $returnconflict
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
	tree *root 1>&2;

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
		#did not exist on last sync -- echo "returned $existed";
		if [[ $existed == "0" ]]; then 
			echo "$conflict HAS BEEN CREATED LOCALLY" 1>&2 ;
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
				echo "$conflict: DELETED ON SERVER BUT CHANGED LOCALLY" 1>&2 ;
				current_t="DIR_DELETED_SERVER_CHANGED_LOCAL"; 
				chksum_c=`get_checksum "$GR_LOCALROOT$conflict"`
				chksum_s="-";  #invalid?  - file deleted
				#if we got solution, and is it useable.  use it.  else set conflictstate
				echo "solution type: $solution_conflict_type" 1>&2;
				echo "current state: $current_t" 1>&2;

				if [ "$solution_conflict_type" == "DIR_DELETED_SERVER_CHANGED_LOCAL" ]; then
					echo "got solution, checking if we got usable solution" 1>&2;
					#chksums correct? -TODO we overwriting/deleting without mutex
					#chk chksum for the file/dir to be deleted
					case "$solution_action" in
						COPY_TO_SERVER)
						echo "copying $GR_LOCALROOT$conflict to server" 1>&2;
						#chksum match?
						if [ $solution_chksumlocal == $chksum_c ]; then 
							#TODO check return code!
							copy_data $conflict $GR_LOCALROOT $GR_SERVERROOT
						else 
							echo "chksum mismatch for solution";
							exit 1

						fi #chksum match
						;;
						DELETE_SERVER)
						echo "Already deleted on server!" 1>&2;
						exit 1;
						;;
						COPY_TO_LOCAL)
						echo "Already deleted on server!" 1>&2;
						exit 1;
						;;
						DELETE_LOCAL)

						if [ $chksum_c == $solution_chksumlocal ]; then
							echo "deleting local dir: $GR_LOCALROOT$conflict" 1>&2;
							delete_data $conflict $GR_LOCALROOT;
						else
							echo "chksum mismatch for solution";
							exit 1
						fi #chksum valid
						;;
						*)
						echo "Unknown action: [$solution_action]";
						exit 1
					esac
				else
					set_conflict_state  "$conflict\nDIR_DELETED_SERVER_CHANGED_LOCAL\n$chksum_c\n$chksum_s";
					#give user the choice between copying or delete
				fi

			else #$changed == "0" -- not changed locally
				echo "$conflict: DELETED ON SERVER, UNCHANGED LOCALLY - DELETE FROM LOCAL" 1>&2 ;
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
					echo "$conflict: FILE CHANGED BOTH LOCALLY AND REMOTELY -- CONFLICT" 1>&2  ;
					chksum_c=`get_checksum "$GR_LOCALROOT$conflict"`
					chksum_s=`calc_remote_file_checksum $GR_SERVER "$GR_SERVERROOT$conflict"`

					if [ "$solution_conflict_type" == "FILE_CHANGED_BOTH" ]; then
						echo "got solution, checking if we got usable solution" 1>&2;
						#chksums correct? -TODO we overwriting/deleting without mutex
						#chk chksum for the file/dir to be deleted
						case "$solution_action" in
							COPY_TO_SERVER)
							echo "copying $GR_LOCALROOT$conflict to server" 1>&2;
							#chksum match?
							if [[ "$solution_chksumlocal" == "$chksum_c" && "$solution_chksumserver" == "$chksum_s" ]]; then
								#TODO check return code!
								copy_data $conflict $GR_LOCALROOT $GR_SERVERROOT
							else 
								echo "chksum mismatch for solution";

							fi #chksum match
							;;
							DELETE_SERVER)
							echo "changed both places, dont delete server!" 1>&2;
							exit 1;
							;;
							COPY_TO_LOCAL)
							if [[ "$solution_chksumserver" == "$chksum_s" && "$solution_chksumlocal" == "$chksum_c" ]]; then 
								#TODO check return code!
								copy_data $conflict  $GR_SERVERROOT $GR_LOCALROOT
							else 
								echo "chksum mismatch for solution";

							fi #chksum match

							;;
							DELETE_LOCAL)
							echo "changed both places, dont delete local!" 1>&2;
							exit 1
							;;
							*)
							echo "Unknown action: [$solution_action]";
							exit 1
						esac

					else
						set_conflict_state  "$conflict\nFILE_CHANGED_BOTH\n$chksum_c\n$chksum_s";
						#give user the choice between copying or delete
					fi;
					#kij#					solve_conflict "$conflict" "$GR_SERVER:$GR_SERVERROOT" "$GR_LOCALROOT"
					#either a merging or copying of files has taken place
					#in any case we can update database
					#					calculate_file "$GR_LOCALROOT$conflict"
					#					echo calculate_file "$GR_LOCALROOT" "$conflict" 1>&2 ;
					#delete entry from server_conflicts after resolved conflict
					#					server_conflicts=`echo "$server_conflicts" | grep -P -v "^$conflict\$"`;
					#					echo echo "$server_conflicts" | grep -P -v "^$conflict\$" 1>&2 ;
				else #file only changed locally only
					echo "$conflict: FILE CHANGED LOCALLY ONLY -- COPY TO SERVER" 1>&2 ;
					#copy file to server
					copy_data "$conflict" "$GR_LOCALROOT" "$GR_SERVER:$GR_SERVERROOT"
					#delete entry from server_conflicts, since conflict is solved
					server_conflicts=`echo "$server_conflicts" | grep -P -v "^$conflict\$"`;
					#update database accordingly
					calculate_file "$GR_LOCALROOT$conflict";
				fi;
			else #file unchanged locally
				echo "$conflict: FILE CHANGED ON SERVER -- COPY TO LOCAL" 1>&2 ;
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
				echo "$conflict: FILE CREATED LOCALLY -- COPY TO SERVER" 1>&2;
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
					echo "$conflict: FILE DELETED ON SERVER BUT MODIFIED LOCALLY -- CONFLICT" 1>&2 ;
					#kij#
					chksum_c=`get_checksum "$GR_LOCALROOT$conflict"`;
					chksum_s="-"; 

					if [ "$solution_conflict_type" == "FILE_DELETED_SERVER_CHANGED_LOCAL" ]; then
						echo "got solution, checking if we got usable solution" 1>&2;
						#chksums correct? -TODO we overwriting/deleting without mutex
						#chk chksum for the file/dir to be deleted
						case "$solution_action" in
							COPY_TO_SERVER)
							echo "copying $GR_LOCALROOT$conflict to server" 1>&2;
							#chksum match?
							if [ $solution_chksumlocal == $chksum_c ]; then 
								#TODO check return code!
								copy_data $conflict $GR_LOCALROOT $GR_SERVERROOT
							else 
								echo "chksum mismatch for solution" 1>&2;
								exit 1;
							fi #chksum match
							;;
							DELETE_SERVER)
							echo "File already deleted on server!" 1>&2;
							exit 1;
							;;
							COPY_TO_LOCAL)
							echo "File already deleted on server!" 1>&2;
							exit 1;
							;;
							DELETE_LOCAL)

							if [ $chksum_c == $solution_chksumlocal ]; then
								echo "deleting local file: $GR_LOCALROOT$conflict" 1>&2;
								delete_data $conflict $GR_LOCALROOT;
							else
								echo "chksum mismatch for solution" 1>&2;
								exit 1;
							fi #chksum valid
							;;
							*)
							echo "Unknown action: [$solution_action]" 1>&2;
							exit 1
						esac

					else
						set_conflict_state  "$conflict\nFILE_DELETED_SERVER_CHANGED_LOCAL\n$chksum_c\n$chksum_s";
						#give user the choice between copying or delete
					fi

					#file deleted on server, but modified locally
					#					 solve_file_deleted_but_changed_locally "$conflict" "$GR_SERVER:$GR_SERVERROOT" "$GR_LOCALROOT";
				else #file deleted on server, untouched locally
					echo "$conflict: FILE DELETED ON SERVER -- DELETE LOCALLY" 1>&2;
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
	tree *root 1>&2;

	echo Server Conflict List: $server_conflicts 1>&2 ; 
	#take first line from list of conflicts:
	conflict=`echo "$server_conflicts" | head -n 1`
	#then remove that line from server_conflicts
	server_conflicts=`echo "$server_conflicts" | tail --lines=+2`;
	echo "next conflict=$conflict" 1>&2;

	#if it is a directory (which can be identified by the trailing '/')
	if echo $conflict | grep -q -P '/$'; then
		#it means the dir only exists on server and not on client
		#if dir did NOT exist on last sync, it must have been created on server
		file_existed "$GR_LOCALROOT$conflict";
		existed=$?
		#echo "returned $existed";
		if [[ $existed == "0" ]]; then 
			echo "$conflict HAS BEEN CREATED ON SERVER" 1>&2;
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
				echo "$conflict: DELETED ON LOCAL BUT CHANGED ON SERVER" 1>&2;
				solve_dir_deleted_but_changed_on_server "$conflict" "$GR_SERVER:$GR_SERVERROOT" "$GR_LOCALROOT";
			else
				echo "$conflict: DELETED ON LOCAL, UNCHANGED ON SERVER - DELETE FROM SERVER" 1>&2;
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
			echo "$conflict: FILE CREATED ON SERVER -- COPY TO LOCAL" 1>&2;
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
				echo "$conflict: FILE DELETED ON LOCALLY BUT MODIFIED ON SERVER -- CONFLICT" 1>&2;
				#kij#
				chksum_c="-";
				chksum_s=`calc_remote_file_checksum $GR_SERVER "$GR_SERVERROOT$conflict"`

				if [ "$solution_conflict_type" == "FILE_DELETED_LOCAL_CHANGED_SERVER" ]; then
					echo "got solution, checking if we got usable solution" 1>&2;
					#chksums correct? -TODO we overwriting/deleting without mutex
					#chk chksum for the file/dir to be deleted
					case "$solution_action" in
						COPY_TO_SERVER)
						echo "File already deleted local!" 1>&2;
						exit 1;
						;;
						DELETE_SERVER)
						if [ $chksum_s == $solution_chksumserver ]; then
							echo "deleting server file: $GR_SERVERROOT$conflict" 1>&2;
							delete_data $conflict $GR_SERVERROOT;
						else
							echo "chksum mismatch for solution" 1>&2;
							exit 1;
						fi #chksum valid
						;;
						COPY_TO_LOCAL)
						echo "copying $GR_SERVERROOT$conflict to local" 1>&2;
						#chksum match?
						if [ $solution_chksumserver == $chksum_s ]; then 
							#TODO check return code!
							copy_data $conflict $GR_SERVERROOT $GR_LOCALROOT
						else 
							echo "chksum mismatch for solution" 1>&2;
							exit 1;
						fi #chksum match
						;;
						DELETE_LOCAL)
						echo "File already deleted local!" 1>&2;
						exit 1;
						;;
						*)
						echo "Unknown action: [$solution_action]" 1>&2;
						exit 1
					esac

				else
					set_conflict_state  "$conflict\nFILE_DELETED_LOCAL_CHANGED_SERVER\n$chksum_c\n$chksum_s";
					#give user the choice between copying or delete
				fi

				#solve_file_deleted_but_changed_on_server  "$conflict" "$GR_SERVER:$GR_SERVERROOT" "$GR_LOCALROOT";
			else #file deleted on on local machine, untouched on server
				#else file deleted on local machine and unchanged on server
				echo "$conflict: FILE DELETED LOCALLY -- DELETE FROM SERVER" 1>&2;
				#delete the file from server
				delete_data "$conflict" "$GR_SERVER:$GR_SERVERROOT"
				#update database
				delete_file_entry "$GR_LOCALROOT$conflict";
			fi;
		fi;
	fi; #checking for dir vs file;
done; #end of loop through conflicts

echo "##############return###################" 1>&2;
get_conflict_state
