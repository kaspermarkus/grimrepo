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

. metatest/asserts.sh
test_1



#print statistics

print_stat

