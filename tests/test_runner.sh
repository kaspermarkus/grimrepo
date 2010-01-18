#!/bin/bash - 
#===============================================================================
#
#          FILE:  test_runner.sh
# 
#         USAGE:  ./test_runner.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#       CREATED: 01/17/2010 05:38:14 PM UTC
#      REVISION:  ---
#===============================================================================

set -o nounset  # Treat unset variables as an error

#source all files with test_* functions in them
#error if name not uniqe


#take one file as parameter ?
source ../repo_log.sh
source unittester.sh


#number of good tests
let SUCCESS=0
let TESTS=0

function inc_tests {
 let TESTS=$TESTS+1;
}

function get_tests {
return $TESTS
}


function print_stat {

echo "###################"
get_tests
echo "total tests :" $?
echo "successes   :" $SUCCESS 
}


function find_files {
	local IFS="
	"

	a=`find .  -name "*sh" -type f | grep -v test_runner|grep -v unittester` 
	for file in ${a[*]}
	do
		b=`grep " test_" $file |grep function` 
		for line in ${b[*]}
		do
			source $file
    		testfunction=`expr match "$line" 'function \([a-z]*\_[a-zA-Z0-9\_]*\)'`
		    log 0 "running $testfunction@$file"
			$testfunction
		done
	done
}

#print statistics
find_files
print_stat

