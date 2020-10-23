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


subject="$1"
rev="$2"
repo="$3"
root="$repo/$subject/$rev/$subject"
if [ -z $subject ] || [ -z $rev ] || [ ! -d $repo ] || [ ! -d $root ]
then
	usage
fi

echo "Building $root with CodeSonar..."
pushd $root

# The project should be installed by install.sh first
if [ ! -f is_installed ]
then
	echo 'Not installed' && exit
fi

# Build with CodeSonar and report errors.
printf "all: ;\nclean: ;" > po/Makefile
printf "all: ;\nclean: ;" > doc/Makefile
make clean \
	&& codesonar analyze $PWD -project "/benjis/corebench/$subject.$rev" make \
	|| quit "Error building $root."

popd

