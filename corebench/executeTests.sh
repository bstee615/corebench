#!/bin/bash
#This script will download and install the benchmark
#Execute this script in your script-folder that contains files like "grep.regressions.txt"

#TODO The user may specify whether to install 
# 1) the "regression" or the "error"-benchmark. The regression-benchmark also installs the regression-introducing versions.
# 2) the version before and after each commit or just after each commit

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <option> [core|find|grep|make|all] <checkout directory>."
  echo "  test-reg            : Execute test cases BEFORE and AFTER"
  echo "                          regression-introducing commit."
  echo "  test-fix            : Execute test cases BEFORE and AFTER"
  echo "                          regression-fixing commit."
  echo "  test-all            : Execute test cases for all subject versions."
  echo "  analyze-reg         : Analyze subjects BEFORE and AFTER"
  echo "                          regression-introducing commit using analyze.sh."
  echo "  analyze-fix         : Analyze subjects BEFORE and AFTER"
  echo "                          regression-fixing commit using analyze.sh."
  echo "  analyze-all         : Analyze all subject versions using analyze.sh."
  exit 1
fi

echo "Each regression error is identified by the hash-id of the error-fixing commit!"

has_errors=0

if [ "$#" -eq 3 ]; then
  case "$2" in
all)
  subjects=('make' 'grep' 'findutils' 'coreutils');
;;
core*)
;&
coreutils)
  subjects=( 'coreutils' );
;;
find)
;& #Fall through
findutils)
  subjects=( 'findutils' );
;;
grep)
  subjects=( 'grep' );
;;
make)
  subjects=( 'make' );
;;
*)
  echo "Unkown subject $2. Please choose from core, find, grep, and make."
;;
  esac
  basedir=$3
else
  subjects=('make' 'grep' 'findutils' 'coreutils'); #('coreutils' 'findutils' 'grep' 'make');
  basedir=$2  
fi
scriptdir=$(pwd)
repo=git://git.savannah.gnu.org
scriptname=$0

CHECK=1
TEST_REG=2
TEST_FIX=3
TEST_ALL=4
ANALYZE_REG=5
ANALYZE_FIX=6
ANALYZE_ALL=7
printtest=0


if [[ $1 == *"test-reg"* ]]; then
  compile=$TEST_REG
elif [[ $1 == *"test-fix"* ]]; then
  compile=$TEST_FIX
elif [[ $1 == *"test-all"* ]]; then
  compile=$TEST_ALL
elif [[ $1 == *"analyze-reg"* ]]; then
  compile=$ANALYZE_REG
elif [[ $1 == *"analyze-fix"* ]]; then
  compile=$ANALYZE_FIX
elif [[ $1 == *"analyze-all"* ]]; then
  compile=$ANALYZE_ALL
else
  echo "First param must be analyze-reg, analyze-fix, analyze-all, test-reg, test-fix, or test-all"
  exit 1
fi

if ! id -u "r">/dev/null; then
  adduser --disabled-password --gecos '' r
  adduser r sudo
  echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
  chmod 777 /root
  for f in $(find "$HOME" -type d | grep -v "/\."); do chmod 777 $f; done
fi


function quit {
  echo
  echo $1
  echo
  echo Please submit your patches to regression.errors[at]gmail.com.
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

function analyze_rev {
  # The <before-revision> is the last compilable revision *before* the error was introduced OR the bug was fixed
  # The <after-revision> is the first compilable revision *after* the error was introduced OR the bug was fixed. 
  # The revision in the <repository directory> is supposed to be the <after-revision>.
  subject=$1
  before_rev=$2
  after_rev=$3
  if ! [ -e "$basedir/$subject/$after_rev/$subject/is_installed" ]; then
	echo "Not compiled: Cannot analyse ${subject}_$after_rev. Continue with next error."
  else
  	$scriptdir/analysis.sh "$basedir/$subject/$after_rev/$subject" "$subject" $before_rev $after_rev "$scriptdir" || quit "Cannot analyse ${subject}_$after_rev."
  	#echo Skipping analysis o_o
  fi
}


function test_reg_before {
  if [ "$subname" == "core" ]; then
    su -m r -c "$scriptdir/subjects/$subject/tests/${reg_after_rev}_${fix_after_rev}/regression.sh $basedir/$subject/$reg_after_rev/$subject" >/dev/null 2>&1 
    fail_before=$?
  else
    "$scriptdir/subjects/$subject/tests/${reg_after_rev}_${fix_after_rev}/regression.sh" "$basedir/$subject/$reg_after_rev/$subject" >/dev/null 2>&1 
    fail_before=$?
  fi
  

  if [ $fail_before -eq 0 ]; then
    printf "[v] $subname.${fix_after_rev}: Test case PASSED BEFORE regression-INTRODUCING commit\n"
  elif [ $fail_before -eq 1 ]; then
    printf "[x] $subname.${fix_after_rev}: Test case FAILED BEFORE regression-INTRODUCING commit\n"
    has_errors=1
  elif [ $fail_before -eq 32 ]; then
    printf "[ ] $subname.${fix_after_rev}: Skipping test case. Only observable on 32bit kernel\n"
  elif [ $fail_before -eq 999 ]; then
    printf "[?] $subname.${fix_after_rev}: Cannot build revision BEFORE regression-INTRODUCING commit: $before_rev\n"
    has_errors=1
  else 
    printf "[?] $subname.${fix_after_rev}: Test case FAILURE BEFORE regression-INTRODUCING Version! Something went wrong with the test case.\n"
    has_errors=1
  fi
}

function test_reg_after {
  if [ "$subname" == "core" ]; then
    su -m r -c "$scriptdir/subjects/$subject/tests/${reg_after_rev}_${fix_after_rev}/regression.sh $basedir/$subject/$reg_after_rev/$subject" >/dev/null 2>&1 
    fail_after=$?
  else
    "$scriptdir/subjects/$subject/tests/${reg_after_rev}_${fix_after_rev}/regression.sh" "$basedir/$subject/$reg_after_rev/$subject" >/dev/null 2>&1 
    fail_after=$?
  fi
  

  if [ $fail_after -eq 0 ]; then
    printf "[x] $subname.${fix_after_rev}: Test case PASSED AFTER  regression-INTRODUCING commit\n"
    has_errors=1
  elif [ $fail_after -eq 1 ]; then
    printf "[v] $subname.${fix_after_rev}: Test case FAILED AFTER  regression-INTRODUCING commit\n"
  elif [ $fail_after -eq 32 ]; then
    printf "[ ] $subname.${fix_after_rev}: Skipping test case. Only observable on 32bit kernel\n"
  else 
    printf "[?] $subname.${fix_after_rev}: Test case FAILURE AFTER regression-INTRODUCING commit! Something went wrong with the test case.\n"
    has_errors=1
  fi
}

function test_fix_before {
  if [ "$subname" == "core" ]; then
    su -m r -c "$scriptdir/subjects/$subject/tests/${reg_after_rev}_${fix_after_rev}/regression.sh $basedir/$subject/$fix_after_rev/$subject" >/dev/null 2>&1 
    fail_before=$?
  else
    "$scriptdir/subjects/$subject/tests/${reg_after_rev}_${fix_after_rev}/regression.sh" "$basedir/$subject/$fix_after_rev/$subject" >/dev/null 2>&1 
    fail_before=$?
  fi
  
      
  if [ $fail_before -eq 0 ]; then
    printf "[x] $subname.${fix_after_rev}: Test case PASSED BEFORE regression-FIXING commit\n"
    has_errors=1
  elif [ $fail_before -eq 1 ]; then
    printf "[v] $subname.${fix_after_rev}: Test case FAILED BEFORE regression-FIXING commit\n"
  elif [ $fail_before -eq 32 ]; then
    printf "[ ] $subname.${fix_after_rev}: Skipping test case. Only observable on 32bit kernel\n"
  elif [ $fail_before -eq 999 ]; then
    printf "[?] $subname.${fix_after_rev}: Cannot build revision BEFORE regression-FIXING commit: $before_rev\n"
    has_errors=1
    #printf "    See file $errorlog\n"
  else 
    printf "[?] $subname.${fix_after_rev}: Test case FAILURE BEFORE regression-FIXING Version! Something went wrong with the test case.\n"
    has_errors=1
  fi
}

function test_fix_after {
  if [ "$subname" == "core" ]; then
    su -m r -c "$scriptdir/subjects/$subject/tests/${reg_after_rev}_${fix_after_rev}/regression.sh $basedir/$subject/$fix_after_rev/$subject" >/dev/null 2>&1 
    fail_after=$?
  else
    "$scriptdir/subjects/$subject/tests/${reg_after_rev}_${fix_after_rev}/regression.sh" "$basedir/$subject/$fix_after_rev/$subject" >/dev/null 2>&1 
    fail_after=$?
  fi
  

  if [ $fail_after -eq 0 ]; then
    printf "[v] $subname.${fix_after_rev}: Test case PASSED AFTER  regression-FIXING commit\n"
  elif [ $fail_after -eq 1 ]; then
    printf "[x] $subname.${fix_after_rev}: Test case FAILED AFTER  regression-FIXING commit\n"
    has_errors=1
  elif [ $fail_after -eq 32 ]; then
    printf "[ ] $subname.${fix_after_rev}: Skipping test case. Only observable on 32bit kernel\n"
  else 
    printf "[?] $subname.${fix_after_rev}: Test case FAILURE AFTER regression-FIXING commit! Something went wrong with the test case.\n"
    has_errors=1
  fi
}

function test_revs {
  subject=$1
  is_fix=$2
  before_rev=$3
  reg_after_rev=$4
  fix_after_rev=$5

  subname=$(echo $subject | cut -c -4)
  if ! [ -e "$scriptdir/subjects/$subject/tests/${reg_after_rev}_${fix_after_rev}/regression.sh" ] ; then 
    printf "[ ] $subname.${fix_after_rev}: Skipping test case. No test case.\n"
  else
    errorlog=/tmp/errors.log
    if [[ $is_fix -eq 0 ]]; then
      cd "$basedir/$subject/$reg_after_rev/$subject" >/dev/null 2>&1 
      
      #REGRESSION_BEFORE
      git checkout $before_rev -f >$errorlog 2>&1 && "$scriptdir/subjects/$subject/install_quick.sh" "$basedir/$subject/$reg_after_rev/$subject" $before_rev "$scriptdir" >$errorlog 2>&1
      if [[ $? -ne 0 ]]; then
        cd -
        tail $errorlog | sed 's/^/\t/g' >&2
        quit "Cannot go build revision $before_rev!"
      fi
      test_reg_before
    
      #REGRESSION_AFTER
      git checkout $reg_after_rev -f >$errorlog 2>&1 && "$scriptdir/subjects/$subject/install_quick.sh" "$basedir/$subject/$reg_after_rev/$subject" $reg_after_rev "$scriptdir" >$errorlog 2>&1
      if [[ $? -ne 0 ]]; then
        cd -
        tail $errorlog | sed 's/^/\t/g' >&2
        quit "Cannot go back to revision $reg_after_rev!"
      fi
      test_reg_after      

      cd - >/dev/null 2>&1 
    else
      cd "$basedir/$subject/$fix_after_rev/$subject" >/dev/null 2>&1 
      
      #FIXED_BEFORE
      git checkout $before_rev -f >$errorlog 2>&1 && "$scriptdir/subjects/$subject/install_quick.sh" "$basedir/$subject/$fix_after_rev/$subject" $before_rev "$scriptdir" >$errorlog 2>&1
      if [[ $? -ne 0 ]]; then
        cd -
        tail $errorlog | sed 's/^/\t/g' >&2
        quit "Cannot go build revision $before_rev!"
      fi
      test_fix_before

      #FIXED_AFTER
      git checkout $fix_after_rev -f >$errorlog 2>&1 && "$scriptdir/subjects/$subject/install_quick.sh" "$basedir/$subject/$fix_after_rev/$subject" $fix_after_rev "$scriptdir" >$errorlog 2>&1
      if [[ $? -ne 0 ]]; then
        #echo "See file $errorlog"
        cd -
        tail $errorlog | sed 's/^/\t/g' >&2
        quit "Cannot go back to revision $fix_after_rev!"
      fi
      test_fix_after
      
      cd - 2>&1 >& /dev/null
    fi
  fi
}


if ! [ -e "$basedir" ] ; then 
 quit "$basedir does not exist!"
fi

for subject in ${subjects[@]}; do
  check $subject
  echo "-- $subject --"

  start=$(date +%s)  
  while read r_pair; do 
    #timeout after 20min per subject
    if [ $(( $(date +%s) - start)) -gt  1200 ]; then 
      echo "Conservative 20min timeout exceeded."
      break; 
    fi  
    reg=$(echo $r_pair | cut -c -41)
    fix=$(echo $r_pair | cut -c 42-82)
    more_reg=
    more_fix=
    if [[ $reg = \#* ]]; then
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

        if [[ $compile -eq $TEST_REG ]] || [[ $compile -eq $TEST_ALL ]]; then
          test_revs "$subject" 0 $reg_before_rev $reg_after_rev $fix_after_rev; fi 
        if [[ $compile -eq $TEST_FIX ]] || [[ $compile -eq $TEST_ALL ]]; then
          test_revs "$subject" 1 $fix_before_rev $reg_after_rev $fix_after_rev; fi
        
        if [[ $compile -eq $ANALYZE_REG ]] || [[ $compile -eq $ANALYZE_ALL ]]; then
           $scriptdir/analysis.sh "$basedir/$subject/$reg_after_rev/$subject" "$subject" $reg_before_rev $reg_after_rev "$scriptdir" || quit "Cannot analyse ${subject}_$reg_after_rev."; fi
        if [[ $compile -eq $ANALYZE_FIX ]] || [[ $compile -eq $ANALYZE_ALL ]]; then
           $scriptdir/analysis.sh "$basedir/$subject/$fix_after_rev/$subject" "$subject" $fix_before_rev $fix_after_rev "$scriptdir" || quit "Cannot analyse ${subject}_$fix_after_rev."; fi
    
  done < "$scriptdir/subjects/$subject/regressions.txt"
done

if [ $has_errors -ne 0 ]; then
  echo "Test Suite FAILED."
  exit 1
else
  echo "Test Suite SUCCESSFUL."
fi
