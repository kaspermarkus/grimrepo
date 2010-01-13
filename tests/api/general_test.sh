#!/bin/bash

	source `pwd`/.grimreporc




#sync dirs
	rm -rf "${GR_LOCALROOT}" "$GR_SERVERROOT"
	mkdir -p "${GR_LOCALROOT}"{A,B,C}
	touch "${GR_LOCALROOT}"{A/a1,B/b1,B/b2,C/c1}
	cp -r "${GR_LOCALROOT}" "${GR_SERVERROOT}"



#initialize repository
./repo_init.sh
#number of tests
TESTS=0;
#number of good tests
SUCCESS=0;

echo testing:

#1expect no output
let TESTS=TESTS+1
out=`./repo_sync.sh 2> /dev/null`
if [[ ! "$out"=="" ]]; then
	echo 'should be empty';
else
    let SUCCESS=SUCCESS+1
fi


let TESTS=TESTS+1
echo "xxx" > ${GR_LOCALROOT}A/a1
echo "bbb" > ${GR_SERVERROOT}A/a1

cat ${GR_LOCALROOT}A/a1
cat ${GR_SERVERROOT}A/a1
test_out=`./repo_sync.sh`

test_goal="1A/a1
FILE_CHANGED_BOTH
d41d8cd98f00b204e9800998ecf8427e
b8694d27c0f13f22ed3bc610c19ec15"


if [[ "$test_out" == "$test_goal" ]]; then
	echo ok
    let SUCCESS=SUCCESS+1
fi


echo "######results######"
echo "total tests:   $TESTS"
echo "successes  :   $SUCCESS"

