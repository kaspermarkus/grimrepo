#!/bin/bash

####################################################
# GRIM REPO ########################################
####################################################
# text_menus.sh
#
# Holds text version of all the menus presented to user.
#
####################################################

####
# Prints a basic header for the menu, with the 
# text passed as a parameter 
#
# $1 - The string presented in the header
function menu_header {
	text=$1;

	echo "################################################################";
	echo -e "### $text";
	echo "################################################################";
}

####
# Keep getting input while the it is not equal to 
# one of the numbers passed as parameters
# 
# $1 - the allowed numbers (eg. 123)
#
# return - the selected number
function query_untill {
	read -s -n1 choice;
	#continue to query untill user inputs one of the letters in the param
	while [[ "$choice" =~ [^$1] ]]; do
		read -s -n1 choice;
	done; 
	return $choice;	
}

####
# Presents user with a confirmation prompt, asking 
# whether user accepts something, defined by a string
# passed as a parameter. The function returns TRUE if
# user confirms, and FALSE if he declines.
#
# $1 - The string to prompt the user
#
# return - 1 if yes was chosen, else 0
function confirm_menu {
	text=$1;
	#print menu header	
	menu_header "$text";
	#print the Yes/No options
	printf "1) Yes\n"
	printf "2) No\n";
	#get user input (must be 1/2)
	query_untill "12";
	choice=$?;
	#if user chooses 1 (yes), return TRUE
	if [ "$choice" -eq "1" ]; then 
		return 1;
	else 
		return 0;
	fi
}

####
# Should be used when a file only exists on one location
# and not the other. Gives the user the option to either
# copy it, so it exists in both locations, or delete it so
# it does not exist at all. Furthermore, an option exists
# to let user view file info, and one to cancel.
#
# $1 - file: the filename and the path
# $2 - placement: the location where file exists (eg. "server")
# $3 - noexist: the location where it does not exist (eg. "this computer")
#
# returns - the value selected by the user
function file_exists_only_once_menu {
	file=$1;
	placement=$2;
	noexist=$3;

	#print menu header:
	menu_header "File \033[1m$file\033[0m only exists on $placement";
	#print options:
	printf "1) Copy from $placement to $noexists\n";
	printf "2) Delete from $placement\n";
	printf "3) View file info\n";
	printf "0) Cancel\n";
	#get user input and return it:
	query_untill "1239";
	return $?;	
}

####
# Should be used when a file only exists on sever
# and not on local computer. Presents user with the
# option to either copy, delete, view file, or cancel
#
# $1 - file: the filename and path relative to root
function file_exists_server_menu {
	file_exists_only_once_menu "$1" "server" "this computer";
	return $?;
}
####
# Should be used when a file only exists locally only
# and not on server. Presents user with the
# option to either copy, delete, view file, or cancel
#
# $1 - file: the filename and path relative to root
function file_exists_local_menu {
	file_exists_only_once_menu "$1" "this computer" "server";
	return $?;	
}

####
# Should be used when a directory only exists on one location
# and not the other. Gives the user the option to either
# copy it, so it exists in both locations, or delete it so
# it does not exist at all. Furthermore, an option exists
# to let user cancel.
#
# $1 - file: the filename and the path
# $2 - placement: the location where file exists (eg. "server")
# $3 - noexist: the location where it does not exist (eg. "this computer")
#
# returns - the value selected by the user
function dir_exists_only_once_menu {
	dir=$1;
	placement=$2;
	noexist=$3;

	#print menu header:
	menu_header "Directory \033[1m$file\033[0m only exists on $placement";
	#print options:
	printf "1) Copy from $placement to $noexists\n";
	printf "2) Delete from $placement\n";
	printf "0) Cancel\n";
	#get user input and return it:
	query_untill "123";
	return $?;	
}

####
# Should be used when a dir only exists on sever
# and not on local computer. Presents user with the
# option to either copy, delete or cancel
#
# $1 - dir: the dirname and path relative to root
function dir_exists_server_menu {
	dir_exists_only_once_menu "$1" "server" "this computer";
	return $?;
}
####
# Should be used when a dir only exists locally only
# and not on server. Presents user with the
# option to either copy, delete, or cancel
#
# $1 - dir: the dirname and path relative to root
function dir_exists_local_menu {
	dir_exists_only_once_menu "$1" "this computer" "server";
	return $?;	
}


