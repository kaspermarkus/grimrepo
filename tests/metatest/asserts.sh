#!/bin/bash - 
#===============================================================================
#
#          FILE:  asserts.sh
# 
#         USAGE:  ./asserts.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: Kij 
#        AUTHOR: KasperMarkus
#       CREATED: 01/17/2010 05:25:14 PM UTC
#      REVISION:  ---
#===============================================================================
set -o nounset                              # Treat unset variables as an error

function test_1() {
	out="1"
	assert_equal "$out" "1" "Testing simple string"
}

function test_2() {
   out="single string"
   assert_equal "$out" "1" "Testing erroneous function"
}

function test_3() {
   out="1multi
2line
3error"

   assert_equal "$out" "1" "Testing erroneous function"
}



