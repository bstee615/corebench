#! /bin/sh
versiondir=$1

# Exercise bugs in grep-2.13 with -i, -n and an RE of ^$ in a multi-byte locale.
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

if [ $(locale -a | grep "tr_TR.utf8" | wc -l) -ne 1 ]; then
  echo "Install locale tr_TR.utf8 using 'sudo locale-gen tr_TR.UTF-8'"
  exit 255
fi

fail=0

i='\xC4\xB0'
#/home/marcel/work/corerepo/coreutils/be7932e8/coreutils/src/printf "$i$i$i$i$i$i$i\n" > in1 || exit 255
$(dirname $0)/printf "$i$i$i$i$i$i$i\n" > in1 || exit 255
#LC_ALL=C $versiondir/src/grep -i .... in1 > out || exit 255
LC_ALL=tr_TR.utf8 $versiondir/src/grep -i .... in1 > out || exit 255
#echo $?
cat in1
cat out
compare in1 out || fail=1

#if [ $fail -eq 1 ]; then
#  fail=0
#elif [ $fail -eq 0 ]; then
#  fail=1
#fi

exit $fail
