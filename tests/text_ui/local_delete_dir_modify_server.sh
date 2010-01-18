#!/bin/bash

#The case where a directory is deleted on server,
#but where contents (a file) has been modified
#locally

if [ -f ~/.grimreporc ]; then
	source ~/.grimreporc
else
	source `pwd`/.grimreporc
fi
    
source text_ui/general_functions.sh
source unittester.sh

function setup_conflict {
	#delete dir from server
	rm -rf "${GR_LOCALROOT}"C
	echo "changes" > "${GR_SERVERROOT}C/c1"	
}

function test_cancel {
	set_up
	#save original setup for asserts	
	setup_conflict
	expected_localroot=`ls -linR ${GR_LOCALROOT}`
	expected_serverroot=`ls -linR ${GR_SERVERROOT}`
	#run sync with cancel as user selection
	bash "$GR_PATH/text_ui/gr_solve.sh" -p "0" > /dev/null
	#do asserts	
	assert_equal "`ls -linR ${GR_LOCALROOT}`" "$expected_localroot" "Checking localroot for changes (there should be none)";
	assert_equal "`ls -linR ${GR_SERVERROOT}`" "$expected_serverroot" "Checking serverroot for changes (there should be none)";
	tear_down
}

function test_copy {
	set_up
	#save original setup for asserts	
	setup_conflict
	expected_roots=`cd ${GR_SERVERROOT}; du -a --time .` 
	#run sync with cancel as user selection
	bash "$GR_PATH/text_ui/gr_solve.sh" -p "1" > /dev/null
	#do asserts	
	assert_equal "`cd ${GR_LOCALROOT}; du -a --time .`" "$expected_roots" "Checking whether localroot has been updated";
	assert_equal "`cd ${GR_SERVERROOT}; du -a --time .`" "$expected_roots" "Checking serverroot for changes (there should be none)";
	tear_down
}

function test_delete_confirm {
	set_up
	#save original setup for asserts	
	setup_conflict
	expected_roots=`cd ${GR_LOCALROOT}; du -a --time .` 
	#run sync with cancel as user selection
	bash "$GR_PATH/text_ui/gr_solve.sh" -p "21" > /dev/null 
	#do asserts	
	assert_equal "`cd ${GR_LOCALROOT}; du -a --time .`" "$expected_roots" "Checking localroot has been updated";
	assert_equal "`cd ${GR_SERVERROOT}; du -a --time .`" "$expected_roots" "Checking whether serverroot for changes (there should be none)";
	tear_down
}
	
function test_delete_cancel {
	set_up
	#save original setup for asserts	
	setup_conflict
	expected_localroot=`ls -linR ${GR_LOCALROOT}`
	expected_serverroot=`ls -linR ${GR_SERVERROOT}`
	#run sync with cancel as user selection
	bash "$GR_PATH/text_ui/gr_solve.sh" -p "200" > /dev/null
	#do asserts	
	assert_equal "`ls -linR ${GR_LOCALROOT}`" "$expected_localroot" "Checking localroot for changes (there should be none)";
	assert_equal "`ls -linR ${GR_SERVERROOT}`" "$expected_serverroot" "Checking localroot for changes (there should be none)";
	tear_down
}


function diffVars {
	printf "$1" > /tmp/f1;
	printf "$2" > /tmp/f2;
	diff /tmp/f1 /tmp/f2
}	
	
	
	
