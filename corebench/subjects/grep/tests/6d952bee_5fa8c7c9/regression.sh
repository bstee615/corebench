#! /bin/sh
versiondir=$1

#
# Copyright (C) 2012-2013 Free Software Foundation, Inc.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.

if [ $(locale -a | grep "en_US.utf8" | wc -l) -ne 1 ]; then
  echo "Install locale en_US.UTF-8 using 'sudo locale-gen en_US.UTF-8'"
  exit 255
fi

fail=0
echo "abcd" | LC_ALL=en_US.UTF-8 timeout 2s $versiondir/src/grep -F -x -f /dev/null
if [ "$?" -eq "124" ]; then
    fail=1;
fi

#if [ $fail -eq 1 ]; then
#  fail=0
#elif [ $fail -eq 0 ]; then
#  fail=1
#fi

exit $fail
