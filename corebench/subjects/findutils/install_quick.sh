#!/bin/bash
#This script will install findutils

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <repository directory> <revision> <scriptfolder>."
  exit 1
fi

repo=$1
revision=$2
scriptdir=$3

function quit {
  echo findutils_$revision [install.sh]: $1
  exit 1
}
function shorten {
  echo $1 | cut -c -8
}

function patch_configure {
  config=$(pwd)/$(if [ -f "configure.in" ]; then echo "configure.in"; else echo "configure.ac"; fi)
  echo $config
  if [ "$(grep -c "^AM_C_PROTOTYPES" $config)" -ne 0 ]; then
    sed -i.bak 's/^AM_C_PROTOTYPES/dnl AM_C_PROTOTYPES/g' $config >/dev/null 2>&1
    make || echo Failed on purpose
    echo "all: ;" > doc/Makefile
    echo "all: ;" > po/Makefile
  fi
}


if ! [ -e "$repo" ] ; then 
 quit "$repo does not exist!"
fi
cd "$repo"

#patching some problem
export DO_NOT_WANT_CHANGELOG_DRIVER=1
patch_configure

case "$revision" in
8565334*)
  ;&
2d428f8*)
  ;&
6e4cecb*)
    patch -f -d lib < $scriptdir/subjects/findutils/listfile.patch
  ;;
b46b0d8*)
    patch -f -d lib < $scriptdir/subjects/findutils/gnulib_version.patch
  ;;
84aef0e*)
    sed -i.bak 's/last_pred/last_pred2/g' find/tree.c
  ;;
esac
make 

