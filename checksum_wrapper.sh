#!/bin/bash

####################################################
# GRIM REPO ########################################
####################################################
# checksum_wrapper.sh
#
# Wraps the checksum functionality for files and dirs.
# The checksum for a while should change whenever the
# content of the file changes.
# For starters, this is done via the md5sum tool.
# For directories, this is very inefficiently done
# by taking the md5sum of the md5sum+filename of
# all the files found (recursively) in the directory.
#
####################################################


####
# Prints info on the file given as argument to 
# screen.
#
# $1 - path to file, including filename, relative to local
#       root
# $2 - the local root (repository) of the file
function get_checksum {
	filepath=$1;
	localroot=$2;

	if [ -f "$localroot$filepath" ]; then 
		echo "Taking md5 of file: ";
	else 
		echo "Taking md5 of dir: ";	
	fi;
	
}

function first_word {
	#take first word of checksumm
}
function get_dir_checksum {
		
	find . -type f -exec md5sum {} \; | md5sum
}

function get_file_checksum {
	
}
