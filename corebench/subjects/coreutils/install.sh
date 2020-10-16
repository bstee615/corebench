#!/bin/bash
#This script will install coreutils

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <repository directory> <revision> <with-cil> <script-folder>."
  exit 1
fi

repo=$1
revision=$2
cil=$3
scriptdir=$4
if [ -z "$revision" ]; then
  exit 0
fi

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
#function parsetime_patch {
#  patch -f -d gnulib/lib < $scriptdir/subjects/coreutils/parse-time.patch
#}
#function utime_patch {
#  patch -f -d gnulib/lib < $scriptdir/subjects/coreutils/utime.patch || patch -f -d lib < $scriptdir/subjects/coreutils/utime.patch || patch -f -d lib < $scriptdir/subjects/coreutils/utime2.patch || patch -f -d lib < $scriptdir/subjects/coreutils/utime3.patch
#}

function cil_patch {
  patch -f -d lib < $scriptdir/subjects/coreutils/verify_cil.patch || patch -f -d lib < $scriptdir/subjects/coreutils/verify2_cil.patch || patch -f -d lib < $scriptdir/subjects/coreutils/verify3_cil.patch || patch -f -d lib < $scriptdir/subjects/coreutils/verify4_cil.patch
  patch -f -d src < $scriptdir/subjects/coreutils/x2nrealloc_cil.patch || patch -f -d src < $scriptdir/subjects/coreutils/x2nrealloc2_cil.patch
  patch -f -d src < $scriptdir/subjects/coreutils/mpl_cil.patch
}
function stdio_patch {
  patch -f -d lib < $scriptdir/subjects/coreutils/stdio.patch || patch -f -d lib < $scriptdir/subjects/coreutils/stdio2.patch
}
function makefileam_patch {
  patch -f -d src < $scriptdir/subjects/coreutils/Makefileam.patch
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
function bootstrap_patch {
   patch -f < $scriptdir/subjects/coreutils/bootstrap.patch
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
  bootstrap_patch
  ./bootstrap --skip-po --gnulib-srcdir=gnulib-git/gnulib/ || autoreconf -i --force || quit "Cannot bootstrap"
}

if ! [ -e "$repo" ] ; then 
 quit "$repo does not exist!"
fi
cd "$repo"
current_rev=$(shorten $(git rev-parse HEAD || quit "Cannot retrieve hash for current revision from $repo!"))
if ! [[ "$current_rev" == *"$revision"* ]]; then
  master_rev=$(shorten $(git rev-parse master || quit "Cannot retrieve hash for current revision from $repo!"))
  if [[ "master" == *"$revision"* ]] && [[ "$master_rev" == *"$current_rev"* ]]; then
	echo Is Master
  else
	quit "Bug - Wrong revision in this repo! Is $current_rev but
 should be $revision".
  fi
fi

year=$(git show -s --format='%ci' | cut -c -4)
#month=$(echo $date | cut -c 6-9)
#year=$(echo $date | cut -c -4)

if [ $year -ge 2010 ]; then
  automake_patch
fi

export FORCE_UNSAFE_CONFIGURE=1
makefileam_patch
sed -i.bak 's/dist-lzma//g' configure.ac
sed -i.bak '/AM_C_PROTOTYPES/d' configure.ac
sed -i.bak '/AM_C_PROTOTYPES/d' configure.in
sed -i.bak '/AM_C_PROTOTYPES/d' m4/jm-macros.m4
case $revision in
0928c241)
	mkdir lib/uniwidth
	cvs -q -z3 -d :pserver:anonymous@cvs.sv.gnu.org:/sources/gnulib checkout -D 2007-01-01 gnulib
	extensions_patch
	./bootstrap --skip-po || autoreconf -i --force || quit "Cannot bootstrap"
	cil_patch
	xsize_patch
	utimens_patch
	tee_patch
  ;;
86e4b778)
  ;&
20c0b870)
  ;&
b8108fd2)
	bootstrap_timely_gnulib
	cil_patch
	getdate_patch
  ;;
a860ca32)
	bootstrap_timely_gnulib
	cil_patch
	getdate_patch
	cp $scriptdir/subjects/coreutils/verify.h lib
  ;;
ae494d4b)
	perl_patch
	./bootstrap --skip-po || autoreconf -i --force || quit "Cannot bootstrap"
	cil_patch
	getdate_patch
  ;;
77f89d01)
	./bootstrap --skip-po || autoreconf -i --force || quit "Cannot bootstrap"
	gperf_patch
	cil_patch
  ;;
2e636af1)
	automake1_patch
	./bootstrap --skip-po || autoreconf -i --force || quit "Cannot bootstrap"
	cil_patch
	stdio_patch
  ;;
7380cf79)
  ;&
3964d508)
  ;&
7eff5901)
  ;&
6fc0ccf7)
	autoreconf -i --force
	cil_patch
	utimens_patch
	tee_patch
  ;;
a6a447fc)
  ;&
ae571715)
	cvs -q -z3 -d :pserver:anonymous@cvs.sv.gnu.org:/sources/gnulib checkout -D 2007-05-22 gnulib
	extensions_patch
	./bootstrap --skip-po || autoreconf -i --force || ./bootstrap --skip-po || quit "Cannot bootstrap"
	xsize_patch
	cil_patch
	#utimens2_patch
  ;;
*) #default
	./bootstrap --skip-po || autoreconf -i --force || quit "Cannot bootstrap" #remove --skip-po
	cil_patch
	getdate_patch
	stdio_patch
  ;;
esac

echo "all: ;" > doc/Makefile
echo "all: ;" > po/Makefile
#if [ $cil -ne 0 ]; then
#  ./configure CC=cilly LD=cilly CFLAGS="-Wno-error --save-temps" || quit "Cannot configure"
#else 
  ./configure --disable-nls CFLAGS="-Wno-error" || quit "Cannot configure"
#fi

make || (
  echo "all: ;" > doc/Makefile
  echo "all: ;" > po/Makefile
  make || quit "Cannot make"
)
touch is_installed



