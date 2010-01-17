#!/bin/bash - 
#===============================================================================
#
#          FILE:  unittester.sh
# 
#         USAGE:  ./unittester.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: Kij 
#        AUTHOR: KasperMarkus
#       CREATED: 01/17/2010 05:25:14 PM UTC
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

#number of tests
let TESTS=0;
#number of good tests
let SUCCESS=0

function assert_equal {
	echo "####" $3
	let TESTS=TESTS+1
	if [[ ! "$1" == "$2" ]]; then
		echo 'fail';
		return 1;
	
	else
		echo "success"
		let SUCCESS=SUCCESS+1
		return 0;
	fi
}

function print_stat {
 echo "total number of tests:    ${TESTS}"
 echo "total number of success:  ${SUCCESS}"
}
