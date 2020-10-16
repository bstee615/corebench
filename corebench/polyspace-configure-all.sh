#!/bin/bash

quit()
{
	echo "$1"
	exit
}

if [ ! -d "$1" ]
then
	quit "Nuh uh"
fi
if [ ! -d "$2" ]
then
	quit "Nuh uh"
fi

repodir="$1"
scriptdir="$2"

for subject in make #grep #coreutils #findutils 
do
	for revision in $(ls $repodir/$subject)
	do
		revision_dir="$repodir/$subject/$revision/$subject"
		echo "pushd '$revision_dir'"
		pushd $revision_dir
		if [ ! -f is_installed ]
		then
			echo "Not installed"
			popd
			continue
		fi
		#if ls *.psprj 1> /dev/null 2>&1
		#then
		#	echo "Polyspace project already generated"
		#	continue
		#fi
		echo "clean: ;" >> po/Makefile
		echo "clean: ;" >> doc/Makefile
		make clean || quit "'make clean' failed"
		result="./BF_RESULT_$subject.$revision"
		project="$subject.$revision.psprj"
		options='ps-options.txt'
		globalOptions="$scriptdir/global-ps-options.txt"
		if [ -d $result ]; then rm -r $result; fi
		if [ -f $project ]; then rm $project; fi
		if [ -f $options ]; then rm $options; fi
		polyspace-configure -output-options-file $options make || quit 'polyspace-configure failed.'
		polyspace-bug-finder -options-file $options -options-file $globalOptions -results-dir $result || quit 'polyspace run failed.'
		popd
	done
done
