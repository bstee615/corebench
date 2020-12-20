#!/bin/bash
#This script will install findutils

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <repository directory> <revision> <with-cil> <scriptfolder>."
  exit 1
fi

repo=$1
revision=$2
cil=$3
scriptdir=$4

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
  patch -f -d lib < $scriptdir/subjects/findutils/parse-time.patch || patch -f -d gnulib/lib < $scriptdir/subjects/findutils/parse-time.patch || patch -f -d gnulib-git/gnulib/lib < $scriptdir/subjects/findutils/parse-time.patch
}
function getdate_patch {
  patch -f -d lib < $scriptdir/subjects/findutils/getdate.patch || patch -f -d gnulib/lib < $scriptdir/subjects/findutils/getdate.patch
}
function missing_patch {
  patch -f < $scriptdir/subjects/findutils/buildaux.missing.patch
}
function extension_patch {
  patch -f -d gnulib-cvs/gnulib/m4 < $scriptdir/subjects/findutils/extensions.patch || patch -f -d gnulib/m4 < $scriptdir/subjects/findutils/extensions.patch 
  patch -f -d gnulib-cvs/gnulib/m4 < $scriptdir/subjects/findutils/extensions2.patch || patch -f -d gnulib/m4 < $scriptdir/subjects/findutils/extensions2.patch 
}
function rpath_patch {
  patch -f  < $scriptdir/subjects/findutils/config-rpath.patch
}
function m4make_patch {
  patch -f < $scriptdir/subjects/findutils/m4-make.patch
}
function verify_patch {
  patch -f -d gnulib/lib < $scriptdir/subjects/findutils/verify_cil.patch || patch -f -d gnulib/lib < $scriptdir/subjects/findutils/verify2_cil.patch || patch -f -d gnulib/lib < $scriptdir/subjects/findutils/verify3_cil.patch || patch -f -d gnulib/lib < $scriptdir/subjects/findutils/verify4_cil.patch #|| patch -f -d lib < $scriptdir/subjects/findutils/verify_cil.patch || patch -f -d lib < $scriptdir/subjects/findutils/verify2_cil.patch || patch -f -d lib < $scriptdir/subjects/findutils/verify3_cil.patch || patch -f -d lib < $scriptdir/subjects/findutils/verify4_cil.patch
}
function gnulib_version_patch {
  patch -f -d lib < $scriptdir/subjects/findutils/gnulib_version.patch
}
function listfile_patch {
  patch -f -d lib < $scriptdir/subjects/findutils/listfile.patch
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
  extension_patch
  autoreconf -i --force || quit "Autoreconf failed"
  autoconf
}



if ! [ -e "$repo" ] ; then 
 quit "$repo does not exist!"
fi
echo "$repo"
cd "$repo"
current_rev=$(shorten $(git rev-parse HEAD || quit "Cannot retrieve hash for current revision from $repo!"))
if ! [[ "$current_rev" == *"$revision"* ]]; then
  quit "Bug - Wrong revision in this repo! Is $current_rev but should be $revision".
fi

#patching some problem
export DO_NOT_WANT_CHANGELOG_DRIVER=1
#patching old automake de-ANSI-fication problem
sed -i.bak -e 's/AM_C_PROTOTYPES/dnl AM_C_PROTOTYPES/g' -e 's/AC_PREREQ(2.59)/AC_PREREQ(2.64)/g' configure.ac
sed -i.bak 's/AM_C_PROTOTYPES/dnl AM_C_PROTOTYPES/g' configure.in


case "$revision" in
  183115d0)
	rm -rf gnulib
	./import-gnulib.sh || quit "Cannot import gnulib"
  ;;
  e6680237)
	echo Patching findutils_$revision
	missing_patch	
	./import-gnulib.sh 
	 git submodule foreach git checkout b64c50cfe4fca783f23341fffebc7d8f84f58820
	./import-gnulib.sh -d gnulib-git/gnulib/ || quit "Cannot import gnulib"
	parsetime_patch
	sed -i.bak 's@xstrtol_fatal@{}//xstrtol_fatal@g' locate/locate.c
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
  dbcb10e9)
  ;& #fall-through
  66c536bb)
	./import-gnulib.sh #Will fail
	echo CORRECTLY FAILED
	echo Patching findutils_$revision
	extension_patch	
	./import-gnulib.sh || quit "Cannot import gnulib"
  ;;
  b130c9b9) 
  ;& #fall-through
  e8bd5a2c)
  ;& #fall-through
  24bf33c0)
  ;& #fall-through
  091557f6)
	mkdir gnulib-cvs
  	cd gnulib-cvs
  	cvs -q -z3 -d :pserver:anonymous@cvs.sv.gnu.org:/sources/gnulib checkout -D 2007-05-22 gnulib
  	cd ..
	extension_patch
  	./import-gnulib.sh -d gnulib-cvs/gnulib/
	autoreconf -i --force
	touch find/stat_.h
  ;;
  c3b2b1b5)
  ;&	
  24e2271e)
  ;&
  daf7f100)
	import_old false #Will fail
	echo CORRECTLY FAILED
	echo Patching findutils_$revision
	rm -r gnulib
	extension_patch	
	./import-gnulib.sh gnulib-cvs/gnulib/ || quit "Cannot import gnulib"
	autoreconf -i --force  
        touch find/timespec.h
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
	gnulib_version_patch
  ;;
  6e4cecb6)
	m4make_patch
	import_old true
        listfile_patch
  ;;
  85653349)
  ;&
  2d428f84)
	import_old true
	listfile_patch
  ;;
  84aef0ea)
    sed -i.bak 's/last_pred/last_pred2/g' find/tree.c
  ;&
  *)
	./import-gnulib.sh 
	year=$(git show -s --format='%ci' | cut -c -4)
    if [ "$?" -ne "0" ] || [ $year -lt 2008 ]; then
	  import_old true
    fi
  ;;
esac

verify_patch

# Fix "Please port gnulib f*.c to your platform!"
for f in $(ls gnulib/lib/*.c gl/lib/*.c)
do
  sed -i.bak 's/_IO_ferror_unlocked/_IO_EOF_SEEN/g' $f
  sed -i.bak 's/_IO_ftrylockfile/_IO_EOF_SEEN/g' $f
done

for s in gnulib/lib/stdio-impl.h gnulib/lib/stdio.h gnulib/lib/stdio.in.h
do
  if [ -f "$s" ]
  then
    echo "#define _IO_IN_BACKUP 0x100" >> $s
  else
    echo "No file $s found"
  fi
done

# Fix rename in gnulib
sed -i.bak 's/typedef unsigned short security_class_t;/typedef unsigned short security_class_t; typedef security_class_t security_context_t;/g' gnulib/lib/se-selinux.in.h

#if [ $cil ]; then
#  ./configure --disable-nls CC=cilly LD=cilly CFLAGS="-Wno-error --save-temps" || quit "Cannot configure."
#else 
  ./configure --disable-nls || quit "Cannot configure."
#fi

printf "all: ;\nclean: ;" > doc/Makefile
printf "all: ;\nclean: ;" > po/Makefile
make || quit "Cannot make"
touch is_installed


