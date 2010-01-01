#!/bin/bash

#sets up a test case for repo_sync and repo_watch
if [ -f ~/.grimreporc ]; then
	source ~/.grimreporc
else 
	source `pwd`/.grimreporc
fi
function do_test {
	#make two identical dirs
	rm -rf "${GR_LOCALROOT}" "$GR_SERVERROOT"
	mkdir -p ${GR_LOCALROOT}{A,B,C}
	touch ${GR_LOCALROOT}{A/a1,B/b1,B/b2,C/c1}
	cp -r ${GR_LOCALROOT} ${GR_SERVERROOT}

	workingdir=`pwd`;

	#initialize repository
	./repo_init.sh

	touch ${GR_SERVERROOT}A/a2
	#make directory locally
	./repo_sync.sh
}
