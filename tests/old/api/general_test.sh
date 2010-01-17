#!/bin/bash

##log line numbers
#set -x
#PS4="($0- ${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]} - [${SHLVL},${BASH_SUBSHELL}, $?"

	source `pwd`/.grimreporc

#sync dirs
	rm -rf "${GR_LOCALROOT}" "$GR_SERVERROOT"
	mkdir -p "${GR_LOCALROOT}"{A,B,C}
	touch "${GR_LOCALROOT}"{A/a1,B/b1,B/b2,C/c1}
	cp -r "${GR_LOCALROOT}" "${GR_SERVERROOT}"

#initialize repository

./repo_init.sh -d 2>/dev/null
echo testing:

#-------------
function 1test_1() {
out=`./repo_sync.sh 2> /dev/null`
assert_equal $out "" "Testing default dont have changes"
}


function 1test_2() {
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



#stat: ------------
echo "######results######"
echo "total tests:   $TESTS"
echo "successes  :   $SUCCESS"

