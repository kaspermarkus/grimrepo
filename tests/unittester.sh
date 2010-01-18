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


function assert_equal {
	resultstr="%-80s  :   %s\n";
	inc_tests
	if [[ ! "$1" == "$2" ]]; then
		state=`echo -e "\E[31;40mfail: $1  expected: $2 \033[0m" `;
		printf "$resultstr" $3 $state
		return 0;
	else
		#33 for yellow
		state=`echo -e "\E[32;40msuccess\033[0m"`;
		printf  "$resultstr" $3 $state
		let SUCCESS=SUCCESS+1
		return 1;
	fi
}

