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

source $GR_PATH/sync_functions.sh
source $GR_PATH/repo_bookkeeper.sh
source $GR_PATH/sql_wrapper.sh
source $GR_PATH/repo_log.sh

if [ -f ~/.grimreporc ]; then
	source ~/.grimreporc
else
	source `pwd`/.grimreporc
fi

while getopts ":hs:" opt; do
	case $opt in
		s)
		log 1 "-s was triggered, Parameter: $OPTARG"
		conflictsolution=$OPTARG;
		;;
		\?)
		log 2 "Invalid option: -$OPTARG" >&2
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

	log 0 "got solving answer: $conflictsolution"
	solution_filename=`printf "$conflictsolution" 	   | head -n 1 | tail -n 1`
	solution_conflict_type=`printf "$conflictsolution" | head -n 2 | tail -n 1`
	solution_chksumlocal=`printf "$conflictsolution"  	   | head -n 3 | tail -n 1`
	solution_chksumserver=`printf "$conflictsolution" 	   | head -n 4 | tail -n 1`
	solution_action=`printf "$conflictsolution" 	   | head -n 5 | tail -n 1`	

	log 0 "solution_filename $solution_filename"
	log 0 "solution conflict_type $solution_conflict_type"
	log 0 "olution_chksumlocal $solution_chksumlocal"
	log 0 "olution_chksumserver $solution_chksumserver"
	log 0 "olution_action $solution_action"



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
			log 2 "Unknown action: [$solution_action]";
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
	log 1 'one conflict already detected, lets solve it first'
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
	log 0 "repo_sync returning conflict state: $returnconflict"
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
	log 0 "`tree *root`";

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
			log 1 "$conflict HAS BEEN CREATED LOCALLY";
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
				log 1 "$conflict: DELETED ON SERVER BUT CHANGED LOCALLY"
				current_t="DIR_DELETED_SERVER_CHANGED_LOCAL"; 
				chksum_c=`get_checksum "$GR_LOCALROOT$conflict"`
				chksum_s="-";  #invalid?  - file deleted
				#if we got solution, and is it useable.  use it.  else set conflictstate
				log 0 "solution type: $solution_conflict_type"
				log 0 "current state: $current_t"

				if [ "$solution_conflict_type" == "DIR_DELETED_SERVER_CHANGED_LOCAL" ]; then
					log 0 "got solution, checking if we got usable solution"
					#chksums correct? -TODO we overwriting/deleting without mutex
					#chk chksum for the file/dir to be deleted
					case "$solution_action" in
						COPY_TO_SERVER)
						log 1 "copying $GR_LOCALROOT$conflict to server"
						#chksum match?
						if [ $solution_chksumlocal == $chksum_c ]; then 
							#TODO check return code!
							copy_data $conflict $GR_LOCALROOT $GR_SERVERROOT
						else 
							log 2 "chksum mismatch for solution";
							exit 1

						fi #chksum match
						;;
						DELETE_SERVER)
						log 2 "Already deleted on server!";
						exit 1;
						;;
						COPY_TO_LOCAL)
						log 2 "Already deleted on server!";
						exit 1;
						;;
						DELETE_LOCAL)

						if [ $chksum_c == $solution_chksumlocal ]; then
							log 1 "deleting local dir: $GR_LOCALROOT$conflict"
							delete_data $conflict $GR_LOCALROOT;
						else
							log 2 "chksum mismatch for solution";
							exit 1
						fi #chksum valid
						;;
						*)
						log 2 "Unknown action: [$solution_action]";
						exit 1
					esac
				else #solution_conflict_type not set, eg. user has not set an action for conflict
					set_conflict_state  "$conflict\nDIR_DELETED_SERVER_CHANGED_LOCAL\n$chksum_c\n$chksum_s";
					#give user the choice between copying or delete
				fi

			else #$changed == "0" -- not changed locally
				log 1 "$conflict: DELETED ON SERVER, UNCHANGED LOCALLY - DELETE FROM LOCAL";
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
					log 1 "$conflict: FILE CHANGED BOTH LOCALLY AND REMOTELY -- CONFLICT";
					chksum_c=`get_checksum "$GR_LOCALROOT$conflict"`
					chksum_s=`calc_remote_file_checksum $GR_SERVER "$GR_SERVERROOT$conflict"`

					if [ "$solution_conflict_type" == "FILE_CHANGED_BOTH" ]; then
						log 0 "got solution, checking if we got usable solution";
						#chksums correct? -TODO we overwriting/deleting without mutex
						#chk chksum for the file/dir to be deleted
						case "$solution_action" in
							COPY_TO_SERVER)
							log 1 "copying $GR_LOCALROOT$conflict to server";
							#chksum match?
							if [[ "$solution_chksumlocal" == "$chksum_c" && "$solution_chksumserver" == "$chksum_s" ]]; then
								#TODO check return code!
								copy_data $conflict $GR_LOCALROOT $GR_SERVERROOT
							else 
								log 2 "chksum mismatch for solution";

							fi #chksum match
							;;
							DELETE_SERVER)
							log 2 "changed both places, dont delete server!";
							exit 1;
							;;
							COPY_TO_LOCAL)
							if [[ "$solution_chksumserver" == "$chksum_s" && "$solution_chksumlocal" == "$chksum_c" ]]; then 
								#TODO check return code!
								copy_data $conflict  $GR_SERVERROOT $GR_LOCALROOT
							else 
								log 2 "chksum mismatch for solution";

							fi #chksum match

							;;
							DELETE_LOCAL)
							log 2 "changed both places, dont delete local!";
							exit 1
							;;
							*)
							log 2 "Unknown action: [$solution_action]";
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
					log 1 "$conflict: FILE CHANGED LOCALLY ONLY -- COPY TO SERVER";
					#copy file to server
					copy_data "$conflict" "$GR_LOCALROOT" "$GR_SERVER:$GR_SERVERROOT"
					#delete entry from server_conflicts, since conflict is solved
					server_conflicts=`echo "$server_conflicts" | grep -P -v "^$conflict\$"`;
					#update database accordingly
					calculate_file "$GR_LOCALROOT$conflict";
				fi;
			else #file unchanged locally
				log 1 "$conflict: FILE CHANGED ON SERVER -- COPY TO LOCAL";
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
				log 1 "$conflict: FILE CREATED LOCALLY -- COPY TO SERVER";
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
					log 1 "$conflict: FILE DELETED ON SERVER BUT MODIFIED LOCALLY -- CONFLICT";
					#kij#
					chksum_c=`get_checksum "$GR_LOCALROOT$conflict"`;
					chksum_s="-"; 

					if [ "$solution_conflict_type" == "FILE_DELETED_SERVER_CHANGED_LOCAL" ]; then
						log 0 "got solution, checking if we got usable solution";
						#chksums correct? -TODO we overwriting/deleting without mutex
						#chk chksum for the file/dir to be deleted
						case "$solution_action" in
							COPY_TO_SERVER)
							log 1 "copying $GR_LOCALROOT$conflict to server";
							#chksum match?
							if [ $solution_chksumlocal == $chksum_c ]; then 
								#TODO check return code!
								copy_data $conflict $GR_LOCALROOT $GR_SERVERROOT
							else 
								log 2 "chksum mismatch for solution";
								exit 1;
							fi #chksum match
							;;
							DELETE_SERVER)
							log 2 "File already deleted on server!";
							exit 1;
							;;
							COPY_TO_LOCAL)
							log 2 "File already deleted on server!";
							exit 1;
							;;
							DELETE_LOCAL)

							if [ $chksum_c == $solution_chksumlocal ]; then
								log 1 "deleting local file: $GR_LOCALROOT$conflict";
								delete_data $conflict $GR_LOCALROOT;
							else
								log 2 "chksum mismatch for solution";
								exit 1;
							fi #chksum valid
							;;
							*)
							log 2 "Unknown action: [$solution_action]";
							exit 1
						esac

					else
						set_conflict_state  "$conflict\nFILE_DELETED_SERVER_CHANGED_LOCAL\n$chksum_c\n$chksum_s";
						#give user the choice between copying or delete
					fi

					#file deleted on server, but modified locally
					#					 solve_file_deleted_but_changed_locally "$conflict" "$GR_SERVER:$GR_SERVERROOT" "$GR_LOCALROOT";
				else #file deleted on server, untouched locally
					log 1 "$conflict: FILE DELETED ON SERVER -- DELETE LOCALLY";
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
	log 0 "`tree *root`";

	log 0 "Server Conflict List: $server_conflicts"
	#take first line from list of conflicts:
	conflict=`echo "$server_conflicts" | head -n 1`
	#then remove that line from server_conflicts
	server_conflicts=`echo "$server_conflicts" | tail --lines=+2`;
	log 0 "next conflict=$conflict";

	#if it is a directory (which can be identified by the trailing '/')
	if echo $conflict | grep -q -P '/$'; then
		#it means the dir only exists on server and not on client
		#if dir did NOT exist on last sync, it must have been created on server
		file_existed "$GR_LOCALROOT$conflict";
		existed=$?
		#echo "returned $existed";
		if [[ $existed == "0" ]]; then 
			log 1 "$conflict HAS BEEN CREATED ON SERVER";
			#dir must have been created on server, copy to local
			copy_data "$conflict" "$GR_SERVER:$GR_SERVERROOT" "$GR_LOCALROOT";
			#update database with the new dir
			calculate_dir "$GR_LOCALROOT$conflict"; 
		else #file existed on last sync
			#dir must have been deleted on remote
			has_dir_changed_remotely "$server_conflicts" "$GR_SERVER" "$GR_SERVERROOT" "$conflict" "$GR_LOCALROOT";
			changed=$?
			if [[ $changed == "1" ]]; then
				log 1 "$conflict: DELETED ON LOCAL BUT CHANGED ON SERVER";
				current_t="DIR_DELETED_LOCAL_CHANGED_SERVER"; 
				chksum_c="-";  #invalid?  - file deleted
				chksum_s=`calc_remote_dir_checksum $GR_SERVER "$GR_SERVERROOT$conflict"`
				#if we got solution, and is it useable.  use it.  else set conflictstate
				log 0 "solution type: $solution_conflict_type"
				log 0 "current state: $current_t"

				if [ "$solution_conflict_type" == "DIR_DELETED_LOCAL_CHANGED_SERVER" ]; then
					log 1 "got solution, checking if we got usable solution"
					#chksums correct? -TODO we overwriting/deleting without mutex
					#chk chksum for the file/dir to be deleted
					case "$solution_action" in
						COPY_TO_SERVER)
						log 2 "Already deleted on local!"
						exit 1;
						;;
						DELETE_SERVER)
						if [ $chksum_s == $solution_chksumserver ]; then
							log 1 "deleting server dir: $GR_SERVER:$GR_SERVERROOT$conflict";
							delete_data $conflict $GR_SERVER:$GR_SERVERROOT;
						else
							log 2 "chksum mismatch for solution";
							exit 1
						fi #chksum valid
						;;
						COPY_TO_LOCAL)
						log 1 "copying $GR_SERVERROOT$conflict to local";
						#chksum match?
						if [ $solution_chksumserver == $chksum_s ]; then 
							#TODO check return code!
							copy_data $conflict $GR_SERVERROOT $GR_LOCALROOT 
						else 
							log 2 "chksum mismatch for solution";
							exit 1
						fi #chksum match

						;;
						DELETE_LOCAL)
						log 2 "Already deleted on local!"
						exit 1;

						;;
						*)
						log 2 "Unknown action: [$solution_action]";
						exit 1
					esac

				else #solution_conflict_type not set, eg. user has not set an action for conflict
					set_conflict_state  "$conflict\nDIR_DELETED_LOCAL_CHANGED_SERVER\n$chksum_c\n$chksum_s";
					#give user the choice between copying or delete
				fi
			else
				log 1 "$conflict: DELETED ON LOCAL, UNCHANGED ON SERVER - DELETE FROM SERVER";
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
			log 1 "$conflict: FILE CREATED ON SERVER -- COPY TO LOCAL";
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
				log 1 "$conflict: FILE DELETED ON LOCALLY BUT MODIFIED ON SERVER -- CONFLICT"
				#kij#
				chksum_c="-";
				chksum_s=`calc_remote_file_checksum $GR_SERVER "$GR_SERVERROOT$conflict"`

				if [ "$solution_conflict_type" == "FILE_DELETED_LOCAL_CHANGED_SERVER" ]; then
					log 1 "got solution, checking if we got usable solution"
					#chksums correct? -TODO we overwriting/deleting without mutex
					#chk chksum for the file/dir to be deleted
					case "$solution_action" in
						COPY_TO_SERVER)
						log 2 "File already deleted local!"
						exit 1;
						;;
						DELETE_SERVER)
						if [ $chksum_s == $solution_chksumserver ]; then
							log 1 "deleting server file: $GR_SERVERROOT$conflict"
							delete_data $conflict $GR_SERVERROOT;
						else
							log 2 "chksum mismatch for solution"
							exit 1;
						fi #chksum valid
						;;
						COPY_TO_LOCAL)
						log 1 "copying $GR_SERVERROOT$conflict to local"
						#chksum match?
						if [ $solution_chksumserver == $chksum_s ]; then 
							#TODO check return code!
							copy_data $conflict $GR_SERVERROOT $GR_LOCALROOT
						else 
							log 2 "chksum mismatch for solution"
							exit 1;
						fi #chksum match
						;;
						DELETE_LOCAL)
						log 2 "File already deleted local!"
						exit 1;
						;;
						*)
						log 2 "Unknown action: [$solution_action]"
						exit 1
					esac

				else
					set_conflict_state  "$conflict\nFILE_DELETED_LOCAL_CHANGED_SERVER\n$chksum_c\n$chksum_s";
					#give user the choice between copying or delete
				fi

				#solve_file_deleted_but_changed_on_server  "$conflict" "$GR_SERVER:$GR_SERVERROOT" "$GR_LOCALROOT";
			else #file deleted on on local machine, untouched on server
				#else file deleted on local machine and unchanged on server
				log 1 "$conflict: FILE DELETED LOCALLY -- DELETE FROM SERVER"
				#delete the file from server
				delete_data "$conflict" "$GR_SERVER:$GR_SERVERROOT"
				#update database
				delete_file_entry "$GR_LOCALROOT$conflict";
			fi;
		fi;
	fi; #checking for dir vs file;
done; #end of loop through conflicts

get_conflict_state
