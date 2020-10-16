#! /bin/sh
versiondir=$1

fail=0
rm y.mk
printf "SHELL:=python^ \nall:; @print 6 " > y.mk

$versiondir/make -f y.mk #&> /dev/null
if [ $? -eq 139 ]; then #segmentation fault
  fail=1
fi

exit $fail
