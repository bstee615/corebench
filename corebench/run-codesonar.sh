#!/bin/bash

function quit()
{
	echo $1
	exit
}

function usage()
{
	quit "Usage: $0 <subject> <revision> </path/to/corerepo>. The project should be installed by install.sh first."
}

if [ -z $1 ] || [ ! -d $2  ] || [ ! -d $3 ]
then
	usage
fi

subject="$1"
rev="$2"
repo="$3"

root="$repo/$subject/$rev/$subject"
echo "Building $root with CodeSonar..."
pushd $root

# The project should be installed by install.sh first
if [ ! -f is_installed ]
then
	echo 'Not installed' && exit
fi

# Build with CodeSonar and report errors.
make clean \
	&& codesonar analyze $PWD -project "/benjis/corebench/$subject.$rev" make \
	|| quit "Error building $root."

popd

