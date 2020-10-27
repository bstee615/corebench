#!/bin/bash
#This script will download and install the benchmark

#TODO The user may specify whether to install 
# 1) the "regression" or the "error"-benchmark. The regression-benchmark also installs the regression-introducing versions.
# 2) the version before and after each commit or just after each commit

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <option> [core|find|grep|make|all] <checkout directory>."
  echo "  compile             : Compile all subjects but stop at the first installation error."
  echo "  compile-all         : Compile all subjects but continue after each installation"
  echo "                        error."
  echo "  check               : Report all (un)compiled revisions."
  exit 1
fi

if [ "$#" -eq 3 ]; then
  case "$2" in
all)
  subjects=('make' 'grep' 'findutils' 'coreutils');
;;
core)
;& #Fall through
coreutils)
  subjects=('coreutils');
;;
find)
;& #Fall through
findutils)
  subjects=('findutils');
;;
grep)
  subjects=('grep');
;;
make)
  subjects=('make');
;;
*)
  echo "Unkown subject $2. Please choose from core, find, grep, and make."
;;
  esac
  opt_2=$2
  basedir=$3
else
  subjects=('make' 'grep' 'findutils' 'coreutils'); #('coreutils' 'findutils' 'grep' 'make');
  basedir=$2  
  opt_2=
fi
scriptdir=$(pwd)
repo=git://git.savannah.gnu.org
scriptname=$0


COMPILE=1
COMPILEALL=2
CHECK=3
cil=0
printtest=0

if [[ $1 == *"-with-cil"* ]]; then
  cil=1
fi
if [[ $1 == *"compile-all"* ]]; then
  compile=$COMPILEALL
elif [[ $1 == *"compile"* ]]; then
  compile=$COMPILE
elif [[ $1 == *"check"* ]]; then
  compile=$CHECK
else
  echo "Second param must be compile, compile-all, or check"
  exit 1
fi
has_errors=0

function print_info {
    echo "Please attempt to compile the following versions manually."     >&2
    cd $scriptdir
    $scriptname check $opt_2 $basedir | grep -e "Not compiled"            >&2
    cd -
    echo ""                                                               >&2
    echo "1) Go to $basedir/<subject>/<revision>/<subject>"               >&2
    echo "   e.g., cd $basedir/grep/3c3bdace/grep."                       >&2
    echo "2) Resolve the problem, build and make."                        >&2
    echo "   Refer to $scriptdir/subjects/<subject>/install.sh for help!" >&2
    echo "3) Execute 'touch is_installed' to mark revision as successfully compiled.">&2
    echo "4) You can run '$0 compile $basedir' and tend to the next problem.">&2
    echo
    echo "Please submit your patches to regression.errors[at]gmail.com."  >&2
}

function quit {
  echo "" >&2
  echo $1 >&2
  echo "" >&2
  print_info
  exit 1
}

function shorten {
  echo $1 | cut -c -8
}

function check {
  subject=$1
  if ! [ -e "$scriptdir/subjects/$subject/regressions.txt" ] ; then 
    quit "$scriptdir/subjects/$subject/regressions.txt does not exist!" 
  fi
  if ! [ -e "$scriptdir/subjects/$subject/install.sh" ] ; then 
    quit "$scriptdir/subjects/$subject/install.sh does not exist!" 
  fi
  if [ -e "$scriptdir/results" ]; then
    if ! [ -e "$scriptdir/results.old" ]; then
	    mkdir "$scriptdir/results.old"
    fi
    cp -rf "$scriptdir/results/." "$scriptdir/results.old" || quit "Cannot save old results."
    rm -rf "$scriptdir/results/"
  fi
  if [ -z $(which git) ] ; then
    quit "Install git (e.g., sudo apt-get install git)"
  fi
  if [ -z $(which autoconf) ] ; then
    quit "Install autoconf (e.g., sudo apt-get install autoconf)"
  fi
  if [ -z $(which autopoint) ] ; then
    quit "Install autopoint (e.g., sudo apt-get install autopoint)"
  fi
  if [ -z $(which libtoolize) ] ; then
    quit "Install libtool (e.g., sudo apt-get install libtool)"
  fi
  if [ $cil -eq 1 ]; then 
    if [ -z $(which cilly) ] ; then
	    quit "Either install the CIL language analysis framework or remove 'CC=cilly LD=cilly' instructions from the install.sh in each subject."
  	fi
  fi
  
  if [ -z $(which bison) ] ; then
    quit "Install bison to build coreutils (e.g., sudo apt-get install bison)"
  fi
  if [ -z $(which gperf) ] ; then
    quit "Install gperf to build coreutils (e.g., sudo apt-get install gperf)"
  fi
  if [ -z $(which makeinfo) ] ; then
    quit "Install texinfo to build coreutils (e.g., sudo apt-get install texinfo)"
  fi
  if [ -z $(which cvs) ] ; then
    quit "Install cvs to build coreutils (e.g., sudo apt-get install cvs)"
  fi
}

function compile_rev {
  subject=$1
  after_rev=$2
  if ! [ -e "$basedir/$subject/$after_rev" ] ; then
    echo "${subject}_$after_rev: Creating $basedir/$subject/$after_rev .."
    mkdir "$basedir/$subject/$after_rev" || quit "${subject}_$after_rev: Cannot make directory $basedir/$subject/$after_rev"
  fi
  if ! [ -e "$basedir/$subject/$after_rev/$subject" ] ; then
	echo "${subject}_$after_rev: Copy $subject from master"
        cp -r "$basedir/$subject/master/$subject" "$basedir/$subject/$after_rev/$subject" 
	if [ $? -ne 0 ]; then 
	  echo "${subject}_$after_rev: Trying to download $subject from repository $repo/$subject.git into $basedir/$subject/$after_rev .." 
	  git clone $repo/$subject.git >/dev/null 2>&1 || quit "${subject}_$after_rev: Cannot download from git-repo $repo/$subject.git"
	fi
	 
  fi
  cd "$basedir/$subject/$after_rev/$subject"
  current_rev=$(shorten $(git rev-parse HEAD || quit "${subject}_$after_rev: Cannot retrieve hash for current revision!"))
  if ! [[ "$current_rev" == *"$after_rev"* ]]; then
    echo "${subject}_$after_rev: Checking out revision $after_rev into $basedir/$subject/$after_rev/$subject .."
    git checkout $after_rev >/dev/null 2>&1 || quit "${subject}_$after_rev: Cannot checkout $after_rev"
  fi
  if ! [ -e "$basedir/$subject/$after_rev/$subject/is_installed" ] ; then
        printf "${subject}_$after_rev: Compiling .. "
    	timeout 10m "$scriptdir/subjects/$subject/install.sh" "$basedir/$subject/$after_rev/$subject" $after_rev $cil "$scriptdir" > /tmp/$subject.$after_rev.errors.log 2>&1 
    if [[ $? -ne 0 ]]; then    
          echo "ERROR!"
          tail /tmp/errors.log | sed 's/^/\t/g' >&2
          has_errors=1
      if [[ $compile -eq $COMPILE ]]; then
        quit "Cannot compile $basedir/$subject/$after_rev using $scriptdir/subjects/$subject/install.sh"
	    fi
    else
      echo "COMPILED!"
    fi
  else
    echo "${subject}_$after_rev: COMPILED"
  fi
}

function check_rev {
  # The <before-revision> is the last compilable revision *before* the error was introduced OR the bug was fixed
  # The <after-revision> is the first compilable revision *after* the error was introduced OR the bug was fixed. 
  # The revision in the <repository directory> is supposed to be the <after-revision>.
  subject=$1
  before_rev=$2
  after_rev=$3
  if ! [ -e "$basedir/$subject/$after_rev/$subject" ] ; then 
    echo "Not downloaded: ${subject}_$after_rev."
  else
    cd "$basedir/$subject/$after_rev/$subject"
    current_rev=$(shorten $(git rev-parse HEAD || echo "Cannot retrieve hash for current revision from $repo!"))
    if ! [[ "$current_rev" == *"$after_rev"* ]]; then
      echo "Wrong revision: ${subject}_$after_rev."
    else
      if ! [ -e "$basedir/$subject/$after_rev/$subject/is_installed" ]; then
        echo "Not compiled: ${subject}_$after_rev."
      else
        echo "Compiled: ${subject}_$after_rev."
      fi 
    fi
  fi
}



function download_master {
  subject=$1
  if ! [ -e "$basedir/$subject" ] ; then 
  	mkdir "$basedir/$subject" || quit "Cannot make directory $basedir/$subject"
  fi

  #Download master (don't compile)
  if ! [ -e "$basedir/$subject/master" ] ; then
    echo "${subject}_master: Creating $basedir/$subject/master .."
    mkdir "$basedir/$subject/master" || quit "${subject}_master: Cannot make directory $basedir/$subject/master"
  fi
  if ! [ -e "$basedir/$subject/master/$subject" ] ; then
    echo "${subject}_master: Downloading $subject from repository $repo/$subject.git into $basedir/$subject/master .."
    cd "$basedir/$subject/master"
    git clone $repo/$subject.git || quit "${subject}_master: Cannot download from git-repo $repo/$subject.git"
  fi
}


if ! [ -e "$basedir" ] ; then 
 quit "$basedir does not exist!"
fi

for subject in ${subjects[@]}; do
  check $subject
  download_master $subject

  if [[ $compile -eq $TEST ]] || [[ $compile -eq $ANALYZE ]]; then
    echo "-- $subject --"
  fi
  while read r_pair; do 
    reg=$(echo $r_pair | cut -c -41)
    fix=$(echo $r_pair | cut -c 42-82)
    more_reg=""
    more_fix=""
    if [[ $reg = \#* ]]; then
      #if [[ $compile -ne $TEST ]] && [[ $compile -ne $ANALYZE ]]; then
      #  echo Skipping $r_pair
      #fi
      continue
    fi
    if [[ $reg = \+* ]]; then
      read more_reg
      reg=$(echo "$reg" | cut -c 2-)
    fi
    if [[ $fix = *+* ]]; then
      read more_fix
      #Two '+' -> shift 2
      if ! [ -z "$more_reg" ]; then
        fix=$(echo "$fix" | cut -c 3-)
      #One '+' -> shift 1
      else 
        fix=$(echo "$fix" | cut -c 2-)
      fi
    fi
	
	reg_before_rev=$(shorten "$reg")^
	fix_before_rev=$(shorten "$fix")^
	reg_after_rev=$(shorten "$reg")
	fix_after_rev=$(shorten "$fix")
	if ! [ -z "$more_reg" ]; then 
	  reg_after_rev=$(shorten "$more_reg") 
	fi
	if ! [ -z "$more_fix" ]; then 
	  fix_after_rev=$(shorten "$more_fix") 
	fi
	
	if [[ $compile -eq $CHECK ]]; then
	  check_rev "$subject"  $reg_before_rev $reg_after_rev
 	  check_rev "$subject" $fix_before_rev $fix_after_rev
	else
	  #Make folder for every revision
	  compile_rev "$subject" $reg_after_rev
	  compile_rev "$subject" $fix_after_rev
	fi

  done < "$scriptdir/subjects/$subject/regressions.txt"
done

#Statistics
if [ $compile -eq $COMPILEALL ] ; then
  if [ $has_errors -ne 0 ]; then
    print_info
  fi
fi

