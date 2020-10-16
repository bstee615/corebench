#!/bin/bash
#This script will install make

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <repository directory> <revision> <with-cil> <script-folder>."
  exit 1
fi

repo=$1
revision=$2
cil=$3
scriptdir=$4

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
current_rev=$(shorten $(git rev-parse HEAD || quit "Cannot retrieve hash for current revision from $repo!"))
if ! [[ "$current_rev" == *"$revision"* ]]; then
  quit "Bug - Wrong revision in this repo! Is $current_rev but should be $revision".
fi

#blindly apply all patches
patch -f < $scriptdir/subjects/make/automake1.patch || patch -f < $scriptdir/subjects/make/automake2.patch
patch -f < $scriptdir/subjects/make/amprog.patch
sed -i.bak 's/^AM_C_PROTOTYPES/dnl AM_C_PROTOTYPES/g' configure.ac
sed -i.bak 's/^AM_C_PROTOTYPES/dnl AM_C_PROTOTYPES/g' configure.in
patch -f < $scriptdir/subjects/make/deansi.patch

touch INSTALL
touch README
touch build.sh.in

if [ ! -f Makefile ]; then
  autoreconf -i --force || quit "Cannot Autoconfigure"
  ./configure --disable-nls || quit "Cannot configure."
fi

patch -f < $scriptdir/subjects/make/depseg.patch 

echo "all: ;" > doc/Makefile
echo "all: ;" > po/Makefile

make CFLAGS="-ggdb -O0 -w" || quit "Cannot build."

touch is_installed



