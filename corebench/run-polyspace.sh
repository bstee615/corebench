#!/bin/bash

function quit()
{
        echo $1
        exit 1
}

function usage()
{
        quit "Usage: $0 <subject> <revision> </path/to/corerepo> </path/to/scripts>. The project should be installed by install.sh first."
}

subject="$1"
rev="$2"
repo="$3"
scriptsdir="$4"
resultsdir="$5"
root="$repo/$subject/$rev/$subject"
if [ -z $subject ] || [ -z $rev ] || [ ! -d $repo ] || [ ! -d $root ] || [ ! -d $scriptsdir ] || [ ! -d $resultsdir ]
then
	usage
fi

echo "Building $root with PolySpace..."

options='ps-options.txt'
globalOptions="$scriptsdir/global-ps-options.txt"
result="$resultsdir/$subject.$rev"

if [ -d $result ]
then
        echo "$result already exists"
        exit 0
fi

pushd $root

# The project should be installed by install.sh first
if [ ! -f is_installed ]
then
	quit 'Not installed'
fi

# Build with Polyspace and report errors.
printf "all: ;\nclean: ;" > po/Makefile
printf "all: ;\nclean: ;" > doc/Makefile
make clean
polyspace-configure -output-options-file $options -allow-overwrite make || quit 'polyspace-configure failed.'
polyspace-bug-finder -options-file $options -options-file $globalOptions -results-dir $result || quit 'polyspace run failed.'

popd

