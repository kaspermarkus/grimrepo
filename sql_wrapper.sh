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

databasename="grim_repo.sqlite";
tablename="checksums";

####
# clear_database
#
# Deletes the entire database (querying user first)
# Usefull when testing the program, needing to clear
# database and set up a testcase
function clear_database {
	rm -i  $databasename;
}

####
# create_database
#
# Creates the database. Does not check if it already exists
# Echoes potential errors
function create_database {
	#create table
	err=`sqlite3 $databasename "CREATE TABLE $tablename ( checksum TEXT, filepath TEXT, UNIQUE(filepath) );"`
	echo sqlite3 $databasename "CREATE TABLE $tablename ( checksum TEXT, filepath TEXT, UNIQUE(filepath) );" 
	#check and react if error occured
	if [ $? != "0" ]; then 
		echo $err;
		exit 30;
	fi;
	err=`sqlite3 $databasename "CREATE INDEX checksum_index on checksums ( checksum );"`;
	#check and react if error occured
	if [ $? != "0" ]; then 
		echo $err;
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

	#check that database exists, else create:
	if [ ! -f "grim_repo.sqlite" ]; then 
		 create_database;
	fi;
	echo	sqlite3 $databasename "$query";
	result=`sqlite3 $databasename "$query"`;
	errorcode=$?;
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

	checksum=`do_query "SELECT checksum FROM $tablename WHERE filepath=\"$filepath\""`;
	errorcode=$?;
	echo "$checksum"
	if [ $errorcode != "0" ]; then 
		echo "ERROR occured while trying to retrieve checksum from database";
		exit 31;
	fi; 
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

echo "do_query INSERT OR REPLACE INTO $tablename ( checksum, filepath ) VALUES ( \"$checksum\", \"$filepath\" )";

	res=`do_query "INSERT OR REPLACE INTO $tablename ( checksum, filepath ) VALUES ( \"$checksum\", \"$filepath\" );"`;
	echo $res
	if [ $? != "0" ]; then 
		echo "ERROR occured while trying to enter or update checksum to database";
		echo "$res";
		exit 32;
	fi; 
}

####
# delete_entry
#
# To be used when a file is deleted from local machine.
# The function simply deletes the file passed as parameter
#
# $1 - filepath: the entire path to the dir or file including filename
function delete_entry {
	filepath=$1;
	res=`do_query "DELETE FROM $tablename WHERE filepath=\"$filepath\""`;
	if [ $? != "0" ]; then 
		echo "ERROR occured while trying to delete entry from database";
		echo "$res";
		exit 33;
	fi;
	#echo do_query "DELETE FROM $tablename WHERE filepath=\"$filepath\" AND local_root=\"$local_root\";";
}

