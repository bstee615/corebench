#! /bin/sh
versiondir=$1

#
# Copyright (C) 2012-2013 Free Software Foundation, Inc.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.


# grep must ignore --devices=ACTION (-D) when reading stdin
# For grep-2.11, this test would fail.
fail=0
#echo foo | $versiondir/src/grep -D skip foo - || fail=1
echo foo | $versiondir/src/grep --devices=skip foo || fail=1

# It's more insidious when the skip option is via the envvar:
#echo foo | GREP_OPTIONS=--devices=skip $versiondir/src/grep foo || fail=1

#if [ $fail -eq 1 ]; then
#  fail=0
#elif [ $fail -eq 0 ]; then
#  fail=1
#fi


exit $fail
