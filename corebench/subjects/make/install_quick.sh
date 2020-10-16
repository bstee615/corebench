#!/bin/bash
#This script will install make

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <repository directory> <revision> <script-folder>."
  exit 1
fi

repo=$1
revision=$2
scriptdir=$3

function quit {
  echo make_$revision [install.sh]: $1
  exit 1
}
function shorten {
  echo $1 | cut -c -8
}

if ! [ -e "$repo" ] ; then 
 quit "$repo does not exist!"
fi
cd "$repo"

config=$(if [ -f configure.in ]; then echo "configure.in"; else echo "configure.ac"; fi)
if [ $(grep -c "^AM_C_PROTOTYPES" $config) -ne 0 ]; then
  sed -i.bak 's/^AM_C_PROTOTYPES/dnl AM_C_PROTOTYPES/g' $config
  patch -f < $scriptdir/subjects/make/deansi.patch
  ./configure
  make || echo supposed to fail
  echo "all: ;" > doc/Makefile
  echo "all: ;" > po/Makefile
fi

make CFLAGS="-ggdb -O0 -w" || (
  echo "all: ;" > doc/Makefile
  echo "all: ;" > po/Makefile
  make CFLAGS="-ggdb -O0 -w"
)

