#!/bin/bash
. sync_functions.sh

if [ -f ~/.grimreporc ]; then
	source ~/.grimreporc
else
	source `pwd`/.grimreporc
fi

for file in `ls $GR_INDEX` ; do
	echo checking: "$file"

	while read file event time; do
		echo $event $time $file 
		
		case $event in
			'CREATE,ISDIR')
			echo 'create mode'
			from=$GR_LOCALROOT
			to=$GR_SERVERROOT
			len=${#GR_LOCALROOT}
			filepath=${file:len}
			copy_data $filepath $from $to
			;;
			*)
			echo "Unknown event, sorry dude\n"
			exit 88;
			;;
		esac
	done < $GR_INDEX/$file
	
	#TODO delete the log-file


done

