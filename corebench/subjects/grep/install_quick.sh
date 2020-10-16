#!/bin/bash
#This script will install grep

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <repository directory> <revision> <script-folder>."
  exit 1
fi

repo=$1
revision=$2
scriptdir=$3

function quit {
  echo grep_$revision [install_grep.sh]: $1
  exit 1
}
function shorten {
  echo $1 | cut -c -8
}
function patch_configure {
  config=$(if [ -f "configure.in" ]; then echo "configure.in"; else echo "configure.ac"; fi)
  if [ "$(grep -c "^AM_C_PROTOTYPES" $config)" -ne 0 ]; then
    sed -i.bak 's/^AM_C_PROTOTYPES/dnl AM_C_PROTOTYPES/g' $config >/dev/null 2>&1
    patch -f -d lib < $scriptdir/subjects/grep/deansi1.patch 
    patch -f -d src < $scriptdir/subjects/grep/deansi2.patch 
  fi
}

function dfasyntax_patch {
  patch -f -d src < $scriptdir/subjects/grep/dfasyntax.patch
}

if ! [ -e "$repo" ] ; then 
 quit "$repo does not exist!"
fi
cd "$repo"


case "$revision" in 
8a025cf*)
  patch_configure
  dfasyntax_patch
  ./autogen.sh
  ./configure
  echo "all: ;" > doc/Makefile
  echo "all: ;" > po/Makefile
  ;;
c4e8205*)
;&
c5a0606*)
  ./bootstrap
  ./configure
  echo "all: ;" > doc/Makefile
  echo "all: ;" > po/Makefile
;;
#    make
#  ;;
#  *) #default
#	make
#  ;;
esac
make || (
  echo "all: ;" > doc/Makefile
  echo "all: ;" > po/Makefile
  make
)
