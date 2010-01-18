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
		result=`echo -ne "\E[35;1m$1\033[0m"`
		expected=`echo -ne "\E[33;1m$2\033[0m"`
		state=`echo -e "\E[31;1mfail:\033[0m\n${result}\n${expected}" `;
		printf "$resultstr" "$3" "$state"
		return 0;
	else
		#33 for yellow
		state=`echo -e "\E[32;1msuccess\033[0m"`;
		printf  "$resultstr" $3 $state
		let SUCCESS=SUCCESS+1
		return 1;
	fi
}

