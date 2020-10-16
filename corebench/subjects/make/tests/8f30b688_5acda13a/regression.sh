#! /bin/sh
versiondir=$1

fail=0
TDIR=$(mktemp -d)
cd $TDIR
printf "# Demonstrate GNU make-3.82 parsing error\n\nutil.a: foo.c bar.c util.a(foo.o bar.o)\n\nfoo.c:\n	echo '#include <stdio.h>' >\$@\n	echo 'void foo(void) {}' >>\$@\n\nbar.c:\n	echo '#include <stdio.h>' >\$@\n	echo 'void bar(void) {}' >>\$@" > Makefile

$versiondir/make 
if [ $? -eq 2 ]; then
  fail=1
fi

cd -
rm -rf $TDIR
#printf "echo This is a command with side-effect >&2\n" > exp
#MAKEFLAGS=n ./make -f Makefile.test > out
#compare exp out || fail=1


exit $fail





 
