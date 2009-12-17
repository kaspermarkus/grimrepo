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

source dialogs.sh

#save localroot and serverroot short path (rootdir/ instead of /home/user/rootdir/)
server_root=`echo $GR_SERVERROOT | sed 's#^.*/\(.\)#\1#'i`
local_root=`echo $GR_LOCALROOT | sed 's#^.*/\(.\)#\1#'i`

#run list rsync changes from server to client
#using head and tail to avoid the garbage info from rsync
s_to_c=`rsync -vrc -n $GR_SERVER:$GR_SERVERROOT $GR_LOCALROOT | tail --lines=+2 | head --lines=-3`
c_to_s=`rsync -vrc -n $GR_LOCALROOT $GR_SERVER:$GR_SERVERROOT | tail --lines=+2 | head --lines=-3`

####
#Takes care of functionality when a file or dir exists on server but not locally
#$1: "directory" or "file"
#$2: $next_entry -- the file/dir in question
#$3: "c_to_s" or "s_to_c", depending on whether we we are copying from server to client,
#       or client to server, respectively.
function selection {
tree *root;

next_entry=$2;

if [[ $3 =~ "s_to_c" ]]; then 
	to="this computer";
	from="server";
	rsyncCopy="$GR_SERVER:\"$GR_SERVERROOT$next_entry\" \"$GR_LOCALROOT$next_entry\""
else 
	to="server";
	from="this computer";
	rsyncCopy="\"$GR_LOCALROOT$next_entry\" $GR_SERVER:\"$GR_SERVERROOT$next_entry\""
fi;

#ask user what to do:
echo "--------------------------------------------------------------------";
echo -e "$1 \033[1m$next_entry\033[0m does not exist on $to";
echo "--------------------------------------------------------------------";
printf "1) Copy from $from\n"
printf "2) Delete on $from\n";
read -s -n1 choice;
#continue to query untill user inputs a, b or c
while [[ "$choice" =~ [^12] ]]; do
	read -s -n1 choice;
done; 
#if user chooses 1 copy everything from server to local
if [ $choice == "1" ]; then 
	echo "Copying $next_entry from $from to $to";
	#remove the serverroot part:
	eval rsync -vrlpts $rsyncCopy;
	#echo "rsync -vrlpt $rsyncCopy";
fi
#if user chooses 2, copy everything from client with --delete and -r
if [ $choice == "2" ]; then 
	echo "Deleting $next_entry from $from.";
	if [[ $3 =~ "s_to_c" ]]; then 
		ssh $GR_SERVER "rm -rf \"$GR_SERVERROOT$next_entry\"";
	else 
		rm -rf "$GR_LOCALROOT$next_entry";
	fi;
fi
#Since we either copied or deleted everything in the $next_entry dir (or file)
#we can safely delete all subdirs and files from $s_to_c and $c_to_s
s_to_c=`echo "$s_to_c" | grep -P -v "^$next_entry"`;
c_to_s=`echo "$c_to_s" | grep -P -v "^$next_entry"`;
}

#First consider the files that are conflicting from server to local (c_to_s):
while [ `echo $c_to_s | wc -w` != 0 ]; do 
	#take first line from c_to_s and save it in $next_entry:
	next_entry=`echo "$c_to_s" | head -n 1`
	#then remove that line from c_to_s
	c_to_s=`echo "$c_to_s" | tail --lines=+2`;
	#echo "next entry=$next_entry";

	#if it is a directory (which can be identified by the trailing '/')
	#the dir only exists on server, and not on locally
	if echo $next_entry | grep -q -P '/$'; then
		selection "directory" "$next_entry" "c_to_s";
	else
		#check if file exists both locally and on server
		#this is the case if $next_entry is in $s_to_c
		if echo "$s_to_c" | grep -q $next_entry; then
			#echo "CONFLICT: $next_entry $s_to_c";
			#remove inconsistencies fom $next_entry (via ??)
			solve_conflict "$next_entry";
			#remove $next_entry from opposite list (that is s_to_c)
			s_to_c=`echo "$s_to_c" | grep -P -v "^$next_entry$"`;	
			#echo "RESOLVED: $s_to_c";
		else 
			selection "file" "$next_entry" "c_to_s";
		fi;
	fi;

done;

echo "=====================================================================================";
#then consider the files that are conflicting from local to server (s_to_c):
while [ `echo $s_to_c | wc -w` != 0 ]; do 
	#take first line from s_to_c and save it in $next_entry:
	next_entry=`echo "$s_to_c" | head -n 1`
	#then remove that line from s_to_c
	s_to_c=`echo "$s_to_c" | tail --lines=+2`;
    	#echo "next entry=$next_entry";

	#if it is a directory (which can be identified by the trailing '/')
	#the dir only exists on server, and not on locally
	if echo $next_entry | grep -q -P '/$'; then
		selection "directory" "$next_entry" "s_to_c";
	else
		#check if file exists both locally and on server
		#this is the case if $next_entry is in $c_to_s
		if echo "$c_to_s" | grep -q $next_entry; then
			echo "CONFLICT: $next_entry";
			#remove inconsistencies fom $next_entry (via ??)
			solve_conflict "$next_entry"
			#remove $next_entry from opposite list (that is s_to_c)
			c_to_s=`echo "$c_to_s" | grep -P -v "^$next_entry$"`;	
			#echo "RESOLVED: $s_to_c";
		else 
			selection "file" "$next_entry" "s_to_c";
		fi;
	fi;
	
done;
