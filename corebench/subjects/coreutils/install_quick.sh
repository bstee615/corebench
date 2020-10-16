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
  echo coreutils_$after_rev [install_quick.sh]: $1
  exit 1
}
function shorten {
  echo $1 | cut -c -8
}


if ! [ -e "$repo" ] ; then 
 quit "$repo does not exist!"
fi
cd "$repo"

export FORCE_UNSAFE_CONFIGURE=1
export SHELL=/bin/bash
#CIL patches
#patch -f -d src < $scriptdir/subjects/coreutils/x2nrealloc_cil.patch || patch -f -d src < $scriptdir/subjects/coreutils/x2nrealloc2_cil.patch
#patch -f -d src < $scriptdir/subjects/coreutils/mpl_cil.patch
#patch -f -d lib < $scriptdir/subjects/coreutils/stdio.patch || patch -f -d lib < $scriptdir/subjects/coreutils/stdio2.patch
sed -i.bak 's/dist-lzma//g' configure.ac
sed -i.bak '/AM_C_PROTOTYPES/d' configure.ac
sed -i.bak '/AM_C_PROTOTYPES/d' configure.in
sed -i.bak '/AM_C_PROTOTYPES/d' m4/jm-macros.m4
patch -f -d src < $scriptdir/subjects/coreutils/x2nrealloc_cil.patch || patch -f -d src < $scriptdir/subjects/coreutils/x2nrealloc2_cil.patch
case "$revision" in
  7eff590*)
    sed -i 's/tee /tee1 /g' src/tee.c
    find . -type f -print0 | xargs -0 sed -i 's/utimens /utimens1 /g'
    autoreconf -i --force
  ;;
  0928c24*)
  ;&
  a6a447f*)
  ;&
  ae57171*)
  ;&
  6c5f11f*)
  ;&
  3964d508)
    #make CFLAGS="-Wno-error"
    autoreconf -i --force
  ;&
  3964d50*)
    find . -type f -print0 | xargs -0 sed -i 's/utimens /utimens1 /g'
    #make CFLAGS="-Wno-error"
    #autoreconf -i --force
  ;;
  3e466ad*)
     patch -f -d src < $scriptdir/subjects/coreutils/mpl_cil.patch
  ;;
  2e636af*)
    patch -f -d src < $scriptdir/subjects/coreutils/Makefileam.patch    
  ;;
  6fc0ccf*)
  ;&
  7380cf7*)
    autoreconf -i --force
    find . -type f -print0 | xargs -0 sed -i 's/utimens /utimens1 /g'
    sed -i 's/tee /tee1 /g' src/tee.c
  ;;
  61de57c*)
    patch -f -d src < $scriptdir/subjects/coreutils/Makefileam.patch
  ;;
esac

make CFLAGS="-Wno-error" || (
  patch -f < $scriptdir/subjects/coreutils/gperf.patch
  patch -f -d lib < $scriptdir/subjects/coreutils/stdio.patch || patch -f -d lib < $scriptdir/subjects/coreutils/stdio2.patch
  echo "all: ;" > doc/Makefile
  echo "all: ;" > po/Makefile
  make CFLAGS="-Wno-error"
)


