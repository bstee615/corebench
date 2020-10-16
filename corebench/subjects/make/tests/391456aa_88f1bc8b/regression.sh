#! /bin/bash
versiondir=$1


fail=0
cp $(dirname $0)/test $versiondir/tests/scripts/regression_test
cd $versiondir/tests/

if ! [ -e "run_make_tests" ]; then
  echo "Test script 'run_make_tests' does not exist!"
  exit 255
fi

./run_make_tests -make $versiondir/make regression_test
fail=$?

if [ -e work/regression_test.diff ]; then
  fail=1
fi

cd -

exit $fail
