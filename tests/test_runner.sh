#!/bin/bash - 
#===============================================================================
#
#          FILE:  test_runner.sh
# 
#         USAGE:  ./test_runner.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#       CREATED: 01/17/2010 05:38:14 PM UTC
#      REVISION:  ---
#===============================================================================

set -o nounset  # Treat unset variables as an error

#source all files with test_* functions in them
#error if name not uniqe

. text_ui/server_delete_dir_modify_locally.sh

test_cancel
test_copy
test_delete_confirm
test_delete_cancel

#print statistics
print_stat

