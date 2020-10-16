#!/bin/bash
#This script is a template for your analysis

# The <before-rev> is the last compilable revision *before* the error was introduced OR the bug was fixed
# The <after-rev> is the first compilable revision *after* the error was introduced OR the bug was fixed.
# The revision in the <repository directory> is supposed to be the <after-rev>.

if [ "$#" -ne 5 ]; then
  echo "Usage: $0 <repository directory> <subject> <before-revision> <after-revision> <scriptdir>."
  echo The <before-rev> is the last compilable revision *before* the error was introduced OR the bug was fixed
  echo The <after-rev> is the first compilable revision *after* the error was introduced OR the bug was fixed.
  echo The revision in the <repository directory> is supposed to be the <after-rev>.

  exit 1
fi

repo=$1
subject=$2
before_rev=$3
after_rev=$4
scriptdir=$5
results="$scriptdir/results"

function quit {
  echo
  echo $subject_$after_rev [analysis.sh]: $1
  exit 1
}

if ! [ -e "$scriptdir/difftool.sh" ]; then
  quit "difftool.sh missing. Copy the complete CYCC-files into $scriptdir."
fi
if ! [ -e "$scriptdir/csgconstruct" ]; then
  quit "csgconstruct executable missing. Copy the complete CYCC-files into $scriptdir and then run 'make'."
fi



function shorten {
  echo $1 | cut -c -8
}

if ! [ -e "$repo" ] ; then 
 quit "$repo does not exist!"
fi
cd "$repo"
current_rev=$(shorten $(git rev-parse HEAD || quit "Cannot retrieve hash for current revision from $repo!"))
if ! [[ "$current_rev" == *"$after_rev"* ]]; then
  quit "The revision in $repo is supposed to be $after_rev but turns out to be $current_rev.".
fi

if ! [ -e "$results" ]; then
  mkdir "$results" || quit "Cannot create folder $results" 
fi


######################### ##
##YOUR ANALYSIS GOES HERE ##
############################
echo
echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
echo @@ STARTING ANALYSIS \for ${subject}_$before_rev..$after_rev
echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
echo
echo IMPLEMENT YOUR ANALYSIS INTO analysis.sh
echo
echo @@ END ANALYSIS
