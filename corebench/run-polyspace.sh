#!/bin/bash

function quit()
{
        echo $1
        exit
}

function usage()
{
        quit "Usage: $0 <subject> <revision> </path/to/corerepo> </path/to/scripts>. The project should be installed by install.sh first."
}

if [ -z $1 ] || [ -z $2  ] || [ ! -d $3 ] || [ ! -d $4 ]
then
        usage
fi

subject="$1"
rev="$2"
repo="$3"
scriptsdir="$4"

root="$repo/$subject/$rev/$subject"
echo "Building $root with PolySpace..."

options='ps-options.txt'
globalOptions="$scriptsdir/global-ps-options.txt"
result="$subject.$rev"

pushd $root

make clean
polyspace-configure -output-options-file $options make || quit 'polyspace-configure failed.'
polyspace-bug-finder -options-file $options -options-file $globalOptions -results-dir $result || quit 'polyspace run failed.'

popd

