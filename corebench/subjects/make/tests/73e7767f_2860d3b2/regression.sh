#! /bin/sh
versiondir=$1

# Copyright (C) 2013 Free Software Foundation, Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

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

# Retry a function requiring a sufficient delay to _pass_
# using a truncated exponential backoff method.
#     Example: retry_delay_ dd_reblock_1 .1 6
# This example will call the dd_reblock_1 function with
# an initial delay of .1 second and call it at most 6 times
# with a max delay of 3.2s (doubled each time), or a total of 6.3s
# Note ensure you do _not_ quote the parameter to GNU sleep in
# your function, as it may contain separate values that sleep
# needs to accumulate.
# Further function arguments will be forwarded to the test function.
retry_delay_()
{
  local test_func=$1
  local init_delay=$2
  local max_n_tries=$3
  shift 3 || return 1

  local attempt=1
  local num_sleeps=$attempt
  local time_fail
  while test $attempt -le $max_n_tries; do
    local delay=$(awk -v n=$num_sleeps -v s="$init_delay" \
                  'BEGIN { print s * n }')
    "$test_func" "$delay" "$@" && { time_fail=0; break; } || time_fail=1
    attempt=$(expr $attempt + 1)
    num_sleeps=$(expr $num_sleeps '*' 2)
  done
  test "$time_fail" = 0
}

# Function to check the expected line count in 'out'.
# Called via retry_delay_(). Sleep some time - see retry_delay_() - if the
# line count is still smaller than expected.
wait4lines_ ()
{
 local delay=$1
 local elc=$2 # Expected line count.
 [ $( wc -l < out ) -ge $elc ] || { sleep $delay; return 1; }
}

die() {
  echo "$@" >&2
  exit 1
}


fail=0
TDIR=$(mktemp -d)
cd $TDIR

cat << EOF > Makefile
TARGETS := foo foo.out

.PHONY: all foo.in

all: \$(TARGETS)

%: %.in
	@echo \$@

%.out: %
	@echo \$@

foo.in: ; @:

EOF

printf "foo\nfoo.out\n" > exp
$versiondir/make > out 
compare exp out || fail=1


#rm /tmp/foo.y
rm /tmp/foo.c > /dev/null
#rm /tmp/foo.o

cd -
rm -rf $TDIR

exit $fail





 
