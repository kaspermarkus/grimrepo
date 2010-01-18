#!/bin/bash - 
===============================================================================
#
#          FILE:  general_test.sh
# 
#         USAGE:  ./general_test.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: Dr. Fritz Mehner (fgm), mehner@fh-swf.de
#       COMPANY: FH Südwestfalen, Iserlohn
#       CREATED: 01/17/2010 05:52:29 PM UTC
#      REVISION:  ---
#===============================================================================
if [ -f ~/.grimreporc ]; then
	source ~/.grimreporc
else
	source `pwd`/.grimreporc
fi


set -o nounset                              # Treat unset variables as an error

function 1test_nochanges() {
out=`./repo_sync.sh 2> /dev/null`
assert_equal $out "" "Testing default dont have changes"
}


function 1test_both_files_modified() {
echo "xxx" > ${GR_LOCALROOT}A/a1
echo "bbb" > ${GR_SERVERROOT}A/a1

test_out=`./repo_sync.sh 2>/dev/null`
assert_equal $out ""
test_goal="1A/a1
FILE_CHANGED_BOTH
d41d8cd98f00b204e9800998ecf8427e
b8694d27c0f13f22ed3bc610c19ec15"

assert_equal "$test_out" "$test_goal" "Testing two local file changes" 
}


