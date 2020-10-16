#!/bin/bash
#This script will install coreutils

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <repository directory> <revision> <script-folder>."
  exit 1
fi

repo=$1
revision=$2
scriptdir=$3

function quit {
  echo coreutils_$revision [install.sh]: $1
  exit 1
}
function shorten {
  echo $1 | cut -c -8
}
function automake_patch {
  patch -f < $scriptdir/subjects/coreutils/automake1.patch || patch -f < $scriptdir/subjects/coreutils/automake12.patch || patch -f < $scriptdir/subjects/coreutils/automake2.patch
}
function parsetime_patch {
  patch -f -d gnulib/lib < $scriptdir/subjects/coreutils/parse-time.patch
}
function utime_patch {
  patch -f -d gnulib/lib < $scriptdir/subjects/coreutils/utime.patch || patch -f -d lib < $scriptdir/subjects/coreutils/utime.patch || patch -f -d lib < $scriptdir/subjects/coreutils/utime2.patch || patch -f -d lib < $scriptdir/subjects/coreutils/utime3.patch
}
function getdate_patch {
  patch -f -d lib < $scriptdir/subjects/coreutils/getdate.patch
}
function extensions_patch {
  patch -f -d gnulib/m4 < $scriptdir/subjects/coreutils/extensions.patch
}
function perl_patch {
  patch -f < $scriptdir/subjects/coreutils/perl.patch
}
function gperf_patch {
  patch -f < $scriptdir/subjects/coreutils/gperf.patch
}
function xsize_patch {
  cp $scriptdir/subjects/coreutils/xsize.h lib/
}
function utimens_patch {
  find . -type f -print0 | xargs -0 sed -i 's/utimens /utimens1 /g'
}
function utimens2_patch {
  #TODO only apply to relevant files: cp.c copy.c install.c ..
  find . -type f -print0 | xargs -0 sed -i 's/(utimens /(utimens1 /g'
  find . -type f -print0 | xargs -0 sed -i 's/ utimens / utimens1 /g'
  sed -i 's/^utimens /utimens1 /g' lib/utimens.h
}
function tee_patch {
  sed -i 's/tee /tee1 /g' src/tee.c
}





function bootstrap_timely_gnulib {
  date=$(git show -s --format='%ci')
  if ! [ -e gnulib-git ]; then
  	mkdir gnulib-git
  fi
  cd gnulib-git
  if ! [ -e gnulib ]; then
  	git clone git://git.sv.gnu.org/gnulib.git gnulib
  fi  
  cd gnulib
  git checkout $(git rev-list -n 1 --before="$date" master)
  cd ../..
  patch -f -d gnulib-git/gnulib/m4 < $scriptdir/subjects/coreutils/extensions.patch
  ./bootstrap --gnulib-srcdir=gnulib-git/gnulib/
}

if ! [ -e "$repo" ] ; then 
 quit "$repo does not exist!"
fi
cd "$repo"
current_rev=$(shorten $(git rev-parse HEAD || quit "Cannot retrieve hash for current revision from $repo!"))
if ! [[ "$current_rev" == *"$revision"* ]]; then
  quit "Bug - Wrong revision in this repo! Is $current_rev but should be $revision".
fi


make 
if [ $? -ne 0 ]; then

year=$(git show -s --format='%ci' | cut -c -4)
#month=$(echo $date | cut -c 6-9)
#year=$(echo $date | cut -c -4)

if [ $year -ge 2010 ]; then
  automake_patch
fi

case "$revision" in
  0928c241)
	mkdir lib/uniwidth
	cvs -q -z3 -d :pserver:anonymous@cvs.sv.gnu.org:/sources/gnulib checkout -D 2007-01-01 gnulib
	extensions_patch
	./bootstrap || quit "Cannot bootstrap"
	utime_patch
	xsize_patch
	utimens_patch
	tee_patch
  ;;
  86e4b778)
  ;&
  20c0b870)
  ;&
  b8108fd2)
  ;&
  a860ca32)
	bootstrap_timely_gnulib
	parsetime_patch
	utime_patch
	getdate_patch
  ;;
  ae494d4b)
	perl_patch
	./bootstrap
	parsetime_patch
	utime_patch
	getdate_patch
  ;;
  77f89d01)
	./bootstrap
	gperf_patch
	parsetime_patch
	utime_patch
  ;;
  2e636af1)
	automake1_patch
	./bootstrap
  ;;
  7380cf79)
  ;&
  3964d508)
  ;&
  7eff5901)
  ;&
  6fc0ccf7)
	autoreconf -i --force
	utime_patch
	utimens_patch
	tee_patch
  ;;
  
  a6a447fc)
  ;&
  ae571715)
	cvs -q -z3 -d :pserver:anonymous@cvs.sv.gnu.org:/sources/gnulib checkout -D 2007-05-22 gnulib
	./bootstrap
	xsize_patch
	utime_patch
	utimens2_patch
  ;;

  
  *) #default
	./bootstrap --skip-po || quit "Cannot bootstrap" #remove --skip-po
	parsetime_patch
	utime_patch
	getdate_patch
  ;;
esac

./configure CC=cilly LD=cilly CFLAGS="-Wno-error --save-temps" || quit "Cannot configure"
make || quit "Cannot make"
touch is_installed
fi


