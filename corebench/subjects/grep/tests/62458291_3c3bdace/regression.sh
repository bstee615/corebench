#! /bin/sh
versiondir=$1

# Exercise bugs in grep-2.13 with -i, -n and an RE of ^$ in a multi-byte locale.
#
# Copyright (C) 2012-2013 Free Software Foundation, Inc.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.


fail=0

$versiondir/src/grep -E '(^| )*(a|b)*(c|d)*( |$)' < /dev/null
test $? = 1 || fail=1

#$versiondir/src/grep -Eq '(^| )*( |$)' < /dev/null
#if [ $? -ne 0 ]; then
#  fail=1
#fi

#if [ $fail -eq 1 ]; then
#  fail=0
#elif [ $fail -eq 0 ]; then
#  fail=1
#fi

exit $fail
