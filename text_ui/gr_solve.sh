#!/bin/bash

####################################################
# GRIM REPO ########################################
####################################################
# gr_solve.sh
#
# Used to actively solve conflicts. In case of a conflict
# the user will be presented with a menu on what to
# do to solve it.
#
####################################################

if [ -f ~/.grimreporc ]; then
	source ~/.grimreporc
else
	source `pwd`/.grimreporc
fi
	    
source "$GR_PATH/text_ui/gr_solvefunctions.sh";
#source "${text_ui_base}gr_solvefunctions.sh";
source "$GR_PATH/text_ui/gr_constants.sh";

####
# solves a conflict
#
# $1 - The string presented in the header
function solve_all {
	#sync, and get the newest conflict:
	local conflict=`bash $GR_PATH/text_ui/gr_autosync.sh`;
	echo textui/gr_solve.sh/solve_all recieved conflict: $conflict 1>&2;
	solve_conflict "$conflict";
	local returned=$?;
	#while [[ $conflict != "" ]]; do
		#sync, and get the newest conflict:
	#	conflict=`${text_ui_base}gr_autosync.sh`;
		#if a conflict exists, solve it:
	#	if [[ $conflict != "" ]]; then
	repo_sync.sh -s "$conflict\n${ACTIONS[$returned]}\n"; 
			#echo `solve_conflict "$conflict"`;
	#	fi;
	#done;
}


####
# Presents the user with vimdiff to be able to solve a conflict
#
# $1 - file: conflicting file
# $2 - localroot: the local root
# $3 - tmpfile: the temporary file to edit
function solve_conflict {
	local conflictstring=$1;

	local filename=`printf "$conflictstring" | head -n 1 | tail -n 1`
	local conflict_type=`printf "$conflictstring" | head -n 2 | tail -n 1`
	local md5local=`printf "$conflictstring" | head -n 3 | tail -n 1`
	local md5server=`printf "$conflictstring" | head -n 4 | tail -n 1`
	local returned;
	echo "solve_conflict recieved package: $filename $conflict_type $md5local $md5server" 1>&2;
	
	#figure out what conflict it is, and send it to the correct location
	if [[ $conflict_type == "DIR_DELETED_SERVER_CHANGED_LOCAL" ]]; then
		solve_dir_deleted_but_changed_locally "$filename";
		returned=$?;
	fi;
	if [[ $conflict_type == "DIR_DELETED_LOCAL_CHANGED_SERVER" ]]; then
		solve_dir_deleted_but_changed_on_server "$filename";
		returned=$?;
	fi;
	if [[ $conflict_type == "FILE_DELETED_SERVER_CHANGED_LOCAL" ]]; then
		solve_file_deleted_but_changed_locally "$filename";
		returned=$?;
	fi;
	if [[ $conflict_type == "FILE_DELETED_LOCAL_CHANGED_SERVER" ]]; then
		solve_file_deleted_but_changed_on_server "$filename";
		returned=$?;
	fi;
	return $returned;
}

