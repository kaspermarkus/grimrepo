#!/bin/bash

#The case where a directory is deleted on local,
#but where contents (a file) has been modified
#server

#sets up a test case for repo_sync and repo_watch
if [ -f ~/.grimreporc ]; then
	source ~/.grimreporc
else 
	source `pwd`/.grimreporc
fi

GR_LOCALROOT_ORIG=`echo $GR_LOCALROOT | sed "s/\/\$/_orig/"`
GR_SERVERROOT_ORIG=`echo $GR_SERVERROOT | sed "s/\/\$/_orig/"`

function setup_unittest {
	 #make two identical dirs
        rm -rf "${GR_LOCALROOT}" "$GR_SERVERROOT"
        mkdir -p "${GR_LOCALROOT}"{A,B,C}
        touch "${GR_LOCALROOT}"{A/a1,B/b1,B/b2,C/c1}
        cp -r "${GR_LOCALROOT}" "${GR_SERVERROOT}"

        #initialize repository
        ./repo_init.sh -d
	#delete dir from server
	rm -rf "${GR_LOCALROOT}"C
	echo "changes" > "${GR_SERVERROOT}C/c1"	

	cp -ar ${GR_SERVERROOT} ${GR_SERVERROOT_ORIG}
	cp -ar ${GR_LOCALROOT} ${GR_LOCALROOT_ORIG}
}

function teardown_unittest {
	rm -r ${GR_SERVERROOT_ORIG} ${GR_LOCALROOT_ORIG}
}

test_unit_cancel() {
	setup_unittest
	$GR_PATH/text_ui/gr_solve.sh -p "0"
	#check that nothing has changed
 		
	teardown_unittest 
}

####
# $1 = dir1
# $2 = dir2 -- remote
# $3 = remote login
function check_dir_equality {
	
}
source "`which shunit2`"
