#!/bin/bash

VERBOSE=0;
WARNINGS=1;
ERRORS=2;

PRETEXT[$VERBOSE]="mm: ";
PRETEXT[$WARNINGS]="ww: ";
PRETEXT[$ERRORS]="EE: ";

let GR_VERBOSITY_LEVEL=2

# $1 - seriousness (0 - all, 1 - warnings, 2 - errors)
# $2 - log string
function log {
	local seriousness=$1;
	local log_string=$2;

	if [ $GR_VERBOSITY_LEVEL -le $seriousness ]; then
		printf "${PRETEXT[$seriousness]}$log_string\n" >&2
	fi;
}
