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
current_rev=$(shorten $(git rev-parse HEAD || quit "Cannot retrieve hash for current revision from $repo!"))
if ! [[ "$current_rev" == *"$revision"* ]]; then
  quit "Bug - Wrong revision in this repo! Is $current_rev but should be $revision".
fi


#blindly apply all patches

cp $scriptdir/subjects/make/make.texi doc
#Clean up earlier (master) build

##############
##Uncomment for master build!
##############
# make update  
##############
patch -f < $scriptdir/subjects/make/automake1.patch || patch -f < $scriptdir/subjects/make/automake2.patch
patch -f < $scriptdir/subjects/make/depseg.patch 
make 

if [ $? -ne 0 ]; then
  patch -f < $scriptdir/subjects/make/amprog.patch
  touch INSTALL
  make distclean 
  touch README
  touch build.sh.in

  autoreconf -i --force || quit "Cannot Autoconfigure"
  ./configure CC=cilly LD=cilly CFLAGS="-Wno-error --save-temps" || quit "Cannot configure"
  patch -f < $scriptdir/subjects/make/depseg.patch 
  make || quit "Cannot make"
  patch -f -R < $scriptdir/subjects/make/amprog.patch &> /dev/null
  rm INSTALL &> /dev/null
fi

#revoke patches after build
rm -rf doc/make.texi &> /dev/null
#patch -f -R < $scriptdir/subjects/make/automake1.patch &> /dev/null || patch -f -R < $scriptdir/subjects/make/automake2.patch &> /dev/null



