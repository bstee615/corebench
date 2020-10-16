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
function gettextize_patch {
  grep -v '/dev/tty' < /usr/bin/gettextize > gettextize
  chmod +x gettextize
  ./gettextize -f
  autoreconf
  autoconf
}
function parsetime_patch {
  patch -f -d gnulib/lib < $scriptdir/subjects/findutils/parse-time.patch
}
function getdate_patch {
  patch -f -d lib < $scriptdir/subjects/findutils/getdate.patch
}
function missing_patch {
  patch -f < $scriptdir/subjects/findutils/buildaux.missing.patch
}
function extension_patch {
  patch -f -d gnulib-cvs/gnulib/m4 < $scriptdir/subjects/findutils/extensions.patch 
}
function rpath_patch {
  patch -f  < $scriptdir/subjects/findutils/config-rpath.patch
}
function m4make_patch {
  patch -f < $scriptdir/subjects/findutils/m4-make.patch
}

function import_old {
  quit_on_error=$1
  date="$(git show -s --format='%ci' | cut -c -10)" || quit "Cannot get date!"
  mkdir gnulib-cvs
  cd gnulib-cvs
  cvs -q -z3 -d :pserver:anonymous@cvs.sv.gnu.org:/sources/gnulib checkout -D $date gnulib
  cd ..
  ./import-gnulib.sh gnulib-cvs/gnulib/
  if [ $? -ne 0 ] && $quit_on_error; then
	quit "cannot import old gnulib"
  fi
  autoreconf -i --force || quit "Autoreconf failed"
  autoconf
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
  
  #patching some problem
  export DO_NOT_WANT_CHANGELOG_DRIVER=1

  case "$revision" in
    183115d0)
	  rm -rf gnulib
	  ./import-gnulib.sh || quit "Cannot import gnulib"
    ;;
    e6680237)
	  echo Patching findutils_$revision
	  ./import-gnulib.sh || quit "Cannot import gnulib"
	  parsetime_patch
    ;;
    7dc70069)
    ;& #Fall-through
    e1d0a991)
    ;& #Fall-through
    93623752)
	  echo Patching findutils_$revision
	  missing_patch
	  ./import-gnulib.sh || quit "Cannot import gnulib"
	  parsetime_patch
	  gettextize_patch
    ;;
    b130c9b9) 
    ;& #fall-through
    e8bd5a2c)
    ;& #fall-through
    dbcb10e9)
    ;& #fall-through
    66c536bb)
    ;&
    24bf33c0)
    ;&
    091557f6)
	  ./import-gnulib.sh #Will fail
	  echo CORRECTLY FAILED
	  echo Patching findutils_$revision
	  extension_patch	
	  ./import-gnulib.sh || quit "Cannot import gnulib"
    ;;
    c3b2b1b5)
    ;&
    24e2271e)
	  import_old false #Will fail
	  echo CORRECTLY FAILED
	  echo Patching findutils_$revision
	rm -r gnulib
	extension_patch	
	./import-gnulib.sh gnulib-cvs/gnulib/ || quit "Cannot import gnulib"
	autoreconf -i --force  
    ;;
    f4d8c73d)
    ;& #fall-through
    b445af98)
    ;& #fall-through
    c8491c11)
    ;& #fall-through
    71f10368)
	  echo Patching findutils_$revision
	  ./import-gnulib.sh || quit "Cannot import gnulib"
	  getdate_patch
    ;;
    b46b0d89) 
 	  echo Patching findutils_$revision
	  rpath_patch
	  ./import-gnulib.sh #Will fail
	  echo CORRECTLY FAILED
	  extension_patch	
	  ./import-gnulib.sh || quit "Cannot import gnulib"
    ;;
    6e4cecb6)
	  m4make_patch
	  import_old $true
    ;;
    *)
	  year=$(git show -s --format='%ci' | cut -c -4)
      if [ $year -lt 2008 ]; then
	    import_old true
	  else 
		./import-gnulib.sh || quit "Cannot import gnulib"
		parsetime_patch
      fi
    ;;
  esac

  ./configure CC=cilly LD=cilly CFLAGS="-Wno-error --save-temps" || quit "Cannot configure."
  make || quit "Cannot make"

fi

