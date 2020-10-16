#! /bin/sh
versiondir=$1

fail=0
TDIR=$(mktemp -d)
cd $TDIR

printf "include bar(x).make" > foo.make
printf "foo(x)/tada: \n\t@echo tada" > "bar(x).make"

$versiondir/make -f foo.make 
if [ $? -ne 0 ]; then
  fail=1
fi

cd -
rm -rf $TDIR

#printf "echo This is a command with side-effect >&2\n" > exp
#MAKEFLAGS=n ./make -f Makefile.test > out
#compare exp out || fail=1


exit $fail





 
