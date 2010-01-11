#!/bin/bash

#The case where a directory is deleted on server,
#but where contents (a file) has been modified
#locally

#sets up a test case for repo_sync and repo_watch
if [ -f ~/.grimreporc ]; then
	source ~/.grimreporc
else 
	source `pwd`/.grimreporc
fi
    
source "$GR_PATH/text_ui/gr_solve.sh";

function do_test {
	#make two identical dirs
	rm -rf "${GR_LOCALROOT}" "$GR_SERVERROOT"
	mkdir -p "${GR_LOCALROOT}"{A,B,C}
	touch "${GR_LOCALROOT}"{A/a1,B/b1,B/b2,C/c1}
	cp -r "${GR_LOCALROOT}" "${GR_SERVERROOT}"

	#initialize repository
	./repo_init.sh

	#delete dir from local 
	rm -f "${GR_LOCALROOT}"C/c1
	echo "changes" > "${GR_SERVERROOT}C/c1"	
	solve_all
}

do_test
