#!/bin/bash

####################################################
# GRIM REPO ########################################
####################################################
# sql_wrapper.sh
#
# Wrapper for the SQLite DB... This is in its
# own file, so it is possible to change this "module"
# with something else, like a mySQL database or something
# similar.
#
# The database consists of a single table:
# Database name: grim_repo
# Table name: checksums 
# +-----------------+-------------------+
# | checksum (int)  | filepath (String) |
# +-----------------+-------------------+
####################################################

databasename="$GR_PATH/grim_repo.sqlite";
tablename="checksums";

####
# clear_database
#
# Deletes the entire database (querying user first)
# Usefull when testing the program, needing to clear
# database and set up a testcase
function clear_database {
	rm $sql_wrapper_rm_flag $databasename;
}

####
# create_database
#
# Creates the database. Does not check if it already exists
# Echoes potential errors
function create_database {
	#create table
	err=`sqlite3 $databasename "CREATE TABLE $tablename ( checksum TEXT, filepath TEXT, UNIQUE(filepath) );"`
	log 0 "sqlite3 $databasename \"CREATE TABLE $tablename ( checksum TEXT, filepath TEXT, UNIQUE(filepath) );\"" 
	#check and react if error occured
	if [ $? != "0" ]; then 
		echo $err;
		exit 30;
	fi;
	err=`sqlite3 $databasename "CREATE INDEX checksum_index on checksums ( checksum );"`;
	#check and react if error occured
	if [ $? != "0" ]; then 
		log 2 "$err";
		exit 30;
	fi;
}

####
# do_query
#
# Queries the database with the parameter. Then echoes the result.
# 
# $1 - query: The query for the database
function do_query {
	query=$1;
	#echo "QUERY $query" DONE;
	#check that database exists, else create:
	if [ ! -f "$databasename" ]; then 
		 create_database;
	fi;
	result=`sqlite3 $databasename "$query"`;
	errorcode=$?;
	#echo do query result: $result with errorcode $?;
	echo $result;
	return $errorcode;
}

####
# get_checksum
#
# Retrieves checksum based on filepath and local_root.
# The resulting checksum is echoed back, and nothing 
# is echoed if it does not exist
#
# $1 - filepath: the entire path to the dir or file including filename
function get_checksum {
	filepath=$1;
	#query="\"SELECT checksum FROM $tablename WHERE filepath=\\\"$filepath\\\"
	query="SELECT checksum FROM $tablename WHERE filepath=\"$filepath\"";
	#echo do_query "$query"
	checksum=`do_query "$query"`;
	#result=`sqlite3 $databasename "$query"`;
	errorcode=$?;
	if [ $errorcode != "0" ]; then 
		log 2 "ERROR occured while trying to retrieve checksum from database";
		exit 31;
	fi;
	echo $checksum; 
}

####
# set_checksum
#
# Sets a checksum in the database, for the file defined
# by the parameters passed to the function. It does not
# matter whether the file already exists in the database or
# not. If it exists, the checksum will be updated, if it does
# not exist, it will be inserted as a new entry into the database
#
# $1 - filepath: the entire path to the dir or file including filename
# $2 - checksum: the new checksum
function set_checksum {
	filepath=$1;
	checksum=$2;

	log 0 "do_query INSERT OR REPLACE INTO $tablename ( checksum, filepath ) VALUES ( \"$checksum\", \"$filepath\" )";

	res=`do_query "INSERT OR REPLACE INTO $tablename ( checksum, filepath ) VALUES ( \"$checksum\", \"$filepath\" );"`;
	log 0 "$res"
	if [ $? != "0" ]; then 
		log 2 "ERROR occured while trying to enter or update checksum to database";
		log 2 "$res";
		exit 32;
	fi; 
}

####
# delete_file_entry
#
# To be used when a file is deleted from local machine.
# The function simply deletes the file passed as parameter
#
# $1 - filepath: the entire path to the file including filename
function delete_file_entry {
	filepath=$1;
	res=`do_query "DELETE FROM $tablename WHERE filepath=\"$filepath\""`;
	if [ $? != "0" ]; then 
		log 2 "ERROR occured while trying to delete entry from database";
		log 2 "$res";
		exit 33;
	fi;
}

####
# delete_dir_entry
#
# To be used when a dir is deleted from local machine.
# The function deletes the dir passed as parameter as
# well as all the sub_entries
#
# $1 - filepath: the entire path to the file including filename
function delete_dir_entry {
	filepath=$1;
	res=`do_query "DELETE FROM $tablename WHERE filepath LIKE \"${filepath}%\""`;
	if [ $? != "0" ]; then 
		log 2 "ERROR occured while trying to delete entry from database";
		log 2 "$res";
		exit 33;
	fi;
}
