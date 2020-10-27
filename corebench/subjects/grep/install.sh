#!/bin/bash
#This script will install grep

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <repository directory> <revision> <with-cil> <script-folder>."
  exit 1
fi

repo=$1
revision=$2
cil=$3
scriptdir=$4

function quit {
  echo grep_$revision [install_grep.sh]: $1
  exit 1
}
function shorten {
  echo $1 | cut -c -8
}

function verify_patch {
  patch -f -d lib < $scriptdir/subjects/grep/verify_cil.patch || patch -f -d lib < $scriptdir/subjects/grep/verify2_cil.patch
}
function deansi_patch {
  sed -i.bak 's/^AM_C_PROTOTYPES/dnl AM_C_PROTOTYPES/g' configure.ac
  sed -i.bak 's/^AM_C_PROTOTYPES/dnl AM_C_PROTOTYPES/g' configure.in
  patch -f -d lib < $scriptdir/subjects/grep/deansi1.patch 
  patch -f -d src < $scriptdir/subjects/grep/deansi2.patch 
}
function dfasyntax_patch {
  patch -f -d src < $scriptdir/subjects/grep/dfasyntax.patch
}

if ! [ -e "$repo" ] ; then 
 quit "$repo does not exist!"
fi
cd "$repo"
current_rev=$(shorten $(git rev-parse HEAD || quit "Cannot retrieve hash for current revision from $repo!"))
if ! [[ "$current_rev" == *"$revision"* ]]; then
  quit "Bug - Wrong revision in this repo! Is $current_rev but should be $revision".
fi


case "$revision" in
  62458291)
    echo Patching grep_62458291
    ./bootstrap || echo Failed as it was supposed to.
    git submodule foreach git checkout 44f52a54d2f3c4384b7eebadd9cfb98c82e9378 || quit "Cannot set gnulib-submodule to revision 44f52a54d2"
    ./bootstrap --gnulib-srcdir=gnulib || quit "Cannot bootstrap"
  ;;
  8a025cf8)
	echo Patching grep_8a025cf8
  deansi_patch
  dfasyntax_patch
	./autogen.sh || "Cannot autogen"
  ;;
  db9d6340)
    echo Patching grep_db9d6340
	git submodule foreach git reset --hard
	./bootstrap  || quit "Cannot bootstrap"
  ;;
  #75bc6fb1)
  #  ./bootstrap
  #  autoreconf -i --force
  #;;
  *) #default
	./bootstrap || autoreconf -i --force || quit "Cannot bootstrap"
  ;;
esac

verify_patch

#if [ $cil -eq 1 ]; then
#  ./configure CC=cilly LD=cilly CFLAGS="-Wno-error --save-temps" || quit "Cannot configure."
#else 
  ./configure --disable-nls || quit "Cannot configure."
#fi
printf "all: ;\nclean: ;" > doc/Makefile
printf "all: ;\nclean: ;" > po/Makefile
make || quit "Cannot make"
touch is_installed



