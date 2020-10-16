#! /bin/sh
versiondir=$1

#
# Copyright (C) 2012-2013 Free Software Foundation, Inc.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.


# Emit a header similar to that from diff -u;  Print the simulated "diff"
# command so that the order of arguments is clear.  Don't bother with @@ lines.
emit_diff_u_header_ ()
{
  printf '%s\n' "diff -u $*" \
    "--- $1	1970-01-01" \
    "+++ $2	1970-01-01"
}

# Arrange not to let diff or cmp operate on /dev/null,
# since on some systems (at least OSF/1 5.1), that doesn't work.
# When there are not two arguments, or no argument is /dev/null, return 2.
# When one argument is /dev/null and the other is not empty,
# cat the nonempty file to stderr and return 1.
# Otherwise, return 0.
compare_dev_null_ ()
{
  test $# = 2 || return 2

  if test "x$1" = x/dev/null; then
    test -s "$2" || return 0
    emit_diff_u_header_ "$@"; sed 's/^/+/' "$2"
    return 1
  fi

  if test "x$2" = x/dev/null; then
    test -s "$1" || return 0
    emit_diff_u_header_ "$@"; sed 's/^/-/' "$1"
    return 1
  fi

  return 2
}

if diff_out_=`exec 2>/dev/null; diff -u "$0" "$0" < /dev/null` \
   && diff -u Makefile "$0" 2>/dev/null | grep '^[+]#!' >/dev/null; then
  # diff accepts the -u option and does not (like AIX 7 'diff') produce an
  # extra space on column 1 of every content line.
  if test -z "$diff_out_"; then
    compare_ () { diff -u "$@"; }
  else
    compare_ ()
    {
      if diff -u "$@" > diff.out; then
        # No differences were found, but Solaris 'diff' produces output
        # "No differences encountered". Hide this output.
        rm -f diff.out
        true
      else
        cat diff.out
        rm -f diff.out
        false
      fi
    }
  fi
elif diff_out_=`exec 2>/dev/null; diff -c "$0" "$0" < /dev/null`; then
  if test -z "$diff_out_"; then
    compare_ () { diff -c "$@"; }
  else
    compare_ ()
    {
      if diff -c "$@" > diff.out; then
        # No differences were found, but AIX and HP-UX 'diff' produce output
        # "No differences encountered" or "There are no differences between the
        # files.". Hide this output.
        rm -f diff.out
        true
      else
        cat diff.out
        rm -f diff.out
        false
      fi
    }
  fi
elif ( cmp --version < /dev/null 2>&1 | grep GNU ) > /dev/null 2>&1; then
  compare_ () { cmp -s "$@"; }
else
  compare_ () { cmp "$@"; }
fi

# Usage: compare EXPECTED ACTUAL
#
# Given compare_dev_null_'s preprocessing, defer to compare_ if 2 or more.
# Otherwise, propagate $? to caller: any diffs have already been printed.
compare ()
{
  # This looks like it can be factored to use a simple "case $?"
  # after unchecked compare_dev_null_ invocation, but that would
  # fail in a "set -e" environment.
  if compare_dev_null_ "$@"; then
    return 0
  else
    case $? in
      1) return 1;;
      *) compare_ "$@";;
    esac
  fi
}

if [ $(locale -a | grep "ja_JP.sjis" | wc -l) -ne 1 ]; then
  echo "Install locale ja_JP.sjis using 'sudo locale-gen ja_JP.sjis' or 'sudo locale-gen ja_JP.SHIFT_JIS'"
  exit 255
fi

# % becomes a half-width katakana in SJIS, and an invalid sequence
# in UTF-8. Use this to try skipping implementations that do not
# support SJIS.
encode() { echo "$1" | tr @% '\203\301'; }

fail=0
export LC_ALL=ja_JP.sjis;
encode "@AA" | timeout 1s $versiondir/src/grep -F A
outcome=$?
if [ $outcome -eq 1 ]; then fail=1; fi 
 
#k=0
#test_grep_reject() {
# k=$(expr $k + 1)
# export LC_ALL=$4
# encode "$2" | \
# #LC_ALL=ja_JP.sjis \
# timeout 10s $versiondir/src/grep $1 $(encode "$3") > out$k 2>&1
# outcome=$?
# if [ $outcome -ne 1 ]; then echo "ne1 ($outcome): $1 $3 ($(encode "$3")) $2 ($(encode "$2")) $4"; fi
# test $outcome = 1
#}
#
#test_grep() {
# k=$(expr $k + 1)
# encode "$2" > exp$k
# export LC_ALL=$4
# #export LC_ALL=ja_JP.sjis
# #LC_ALL=ja_JP.sjis \
# timeout 10s $versiondir/src/grep $1 $(encode "$3") exp$k > out$k 2>&1
# outcome=$?
# if [ $outcome -ne 0 ]; then echo "ne0 ($outcome): $1 $3 ($(encode "$3"))  $2 ($(encode "$2")) $4"; fi
# test $outcome = 0 && compare out$k exp$k
#}
#
##test_grep_reject -F @@ @ || echo "system does not seem to know about SJIS" && exit 255 #'system does not seem to know about SJIS'
##test_grep -F %%AA A || echo "system seems to treat SJIS the same as UTF-8" && exit 254 #'system seems to treat SJIS the same as #UTF-8'
#
#failure_tests=@A
#successful_tests='%%AA @AA @A@@A'
#locs='ja_JP.sjis'
#fail=0
#
#for loc in $locs; do
#echo $loc
#
#for i in $successful_tests; do
# test_grep -F $i A $loc || fail=1
# test_grep -E $i A $loc || fail=1
#done
#
#for i in $failure_tests; do
# test_grep_reject -F $i A $loc || fail=1
# test_grep_reject -E $i A $loc || fail=1
#done
#done

#if [ $fail -eq 1 ]; then
#  fail=0
#elif [ $fail -eq 0 ]; then
#  fail=1
#fi

exit $fail
