#!/bin/bash

if [ -f ~/.grimreporc ]; then
	source ~/.grimreporc
else
	source `pwd`/.grimreporc
fi

function set_up {
	#make two identical dirs
	rm -rf "${GR_LOCALROOT}" "$GR_SERVERROOT"
	mkdir -p "${GR_LOCALROOT}"{A,B,C}
	touch "${GR_LOCALROOT}"{A/a1,B/b1,B/b2,C/c1}
	cp -r "${GR_LOCALROOT}" "${GR_SERVERROOT}"

	#initialize repository
	$GR_PATH/repo_init.sh -d
}

function tear_down {
	rm -rf "${GR_LOCALROOT}" "$GR_SERVERROOT"
}
