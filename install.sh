#!/bin/bash

LIB_PATH=`dirname "\`pwd\`/$0"`

#get BIN_PATH
#TODO: check path validity
BIN_PATH="/usr/bin"
printf "Install location for binaries ($BIN_PATH): ";
read bin_selection
if [[ "$bin_selection" != "" ]]; then
	BIN_PATH="$bin_selection";
fi;
echo "bin path now set to: $BIN_PATH";

#TODO: confirm paths by userinput (Y/n)

#fix .grimreporc
#echo sed -i "s#^\(export GR_PATH=\).*#\\1$LIB_PATH#" "$LIB_PATH/.grimreporc";
#echo sed -i "s#^\(export GR_INDEX=\).*#\\1/home/$USER/.grimrepo#" "$LIB_PATH/.grimreporc";
sed -i "s#^\(export GR_PATH=\).*#\\1$LIB_PATH#" "$LIB_PATH/.grimreporc";
sed -i "s#^\(export GR_INDEX=\).*#\\1/home/$USER/.grimrepo#" "$LIB_PATH/.grimreporc";

#copy configs:
mv "$LIB_PATH/.grimreporc" /home/$USER/
mv "$LIB_PATH/.grimrepo" /home/$USER/

#TODO: link to path
#ln -s "$LIB_PATH/repo_init.sh" "$LIB_PATH/repo_sync.sh" "$BIN_PATH";
