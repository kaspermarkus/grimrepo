#!/bin/bash

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
	mkdir -p ${GR_LOCALROOT}{A,B,C}
	touch ${GR_LOCALROOT}{A/a1,B/b1,B/b2,C/c1}
	cp -r ${GR_LOCALROOT} ${GR_SERVERROOT}

	workingdir=`pwd`;

	#initialize repository
	./repo_init.sh

	echo "change1" > ${GR_LOCALROOT}A/a1
	echo "change21" > ${GR_SERVERROOT}A/a1

	#make directory locally
	solve_all
}

do_test
