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
  case "$revision" in
    62458291)
      echo Patching grep_62458291
      git submodule foreach git checkout 44f52a54d2f3c4384b7eebadd9cfb98c82e9378 || quit "Cannot set gnulib-submodule to revision 44f52a54d2"
	  ./bootstrap --gnulib-srcdir=gnulib || quit "Cannot bootstrap"
    ;;
    8a025cf8)
	  echo Patching grep_8a025cf8
	  ./autogen.sh || "Cannot autogen"
    ;;
    db9d6340)
      echo Patching grep_db9d6340
	  git submodule foreach git reset --hard
	  ./bootstrap  || quit "Cannot bootstrap"
    ;;
    *) #default 
      ./bootstrap || quit "Cannot bootstrap"
    ;;
  esac

  ./configure CC=cilly LD=cilly CFLAGS="-Wno-error --save-temps" || quit "Cannot configure" 
  make || quit "Cannot make"
fi
touch is_installed



