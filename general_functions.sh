#!/bin/bash

####################################################
# GRIM REPO ########################################
####################################################
# general_functions.sh
#
# Contains general functions that are usefull in the
# context of grimrepo
#
####################################################

####
# Check whether the path given is local or on a server
# this is identified by whether the path is similar to
# "user@domain:/path/to/repo"
# or 
# "/path/to/repo"
# the first case is obviously on server (remote)
# 
# The function returns 1 if the file is remote
#
# $1 - root (if remote, it should be in the user@server:root syntax)
function is_remote {
	if echo $1 | grep -P -q "^[^@\b]+@[^\b]+:.*"; then 
		return 1; 
	else 
		return 0;
	fi
}
