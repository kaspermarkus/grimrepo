#!/bin/bash

source /home/$USER/.grimreporc

printf "Enter a name for repository ($GR_REPONAME): ";
read repo_name
if [[ "$repo_name" != "" ]]; then
	GR_REPONAME="$repo_name";
fi;
printf "Enter local root ($GR_LOCALROOT): ";
read local_root
if [[ "$local_root" != "" ]]; then
	GR_LOCALROOT="$local_root";
fi;
printf "Enter the server info ($GR_SERVER): ";
read server
if [[ "$server" != "" ]]; then
	GR_SERVER="$server";
fi;
printf "Enter server root ($GR_SERVERROOT): ";
read server_root
if [[ "$server_root" != "" ]]; then
	GR_SERVERROOT="$server_root";
fi;

echo "-------------------------------";
echo "Repository name: $GR_REPONAME";
echo "Local root: $GR_LOCALROOT";
echo "Server info: $GR_SERVER";
echo "Server root: $GR_SERVERROOT";
echo "Is the following information correct? (Y/n) ";

read -n1 -s choice;
while [[ "$choice" =~ [^yYnN] ]]; do
	read -n1 -s choice;	
done;

if [[ $choice == "n" ]]; then 
	echo $GR_PATH/configure.sh
	bash $GR_PATH/configure.sh
fi

#write to config file
sed -i "s#^\(export GR_REPONAME=\).*#\\1$GR_REPONAME#" "/home/$USER/.grimreporc";
sed -i "s#^\(export GR_LOCALROOT=\).*#\\1$GR_LOCALROOT#" "/home/$USER/.grimreporc";
sed -i "s#^\(export GR_SERVER=\).*#\\1$GR_SERVER#" "/home/$USER/.grimreporc";
sed -i "s#^\(export GR_SERVERROOT=\).*#\\1$GR_SERVERROOT#" "/home/$USER/.grimreporc";
