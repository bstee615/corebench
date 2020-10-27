#!/bin/bash

# not_installed(subject). Expects to be run in ~/work/corebench/corerepo!
function not_installed() {
    for d in $(ls | grep -v master)
    do
        if [ -d $d ] && [ -z $(ls $d/$1 | grep is_installed) ]
        then
            echo $d
        fi
    done
}

# run_polyspace_for_file(subject). Expects input file too!
function run_polyspace_for_file() {
    for d in $(cat $1-easy-regressions.txt)
    do
        echo "./run-polyspace.sh $1 $d ~/work/corebench/corerepo/ ~/work/corebench/corebench/ ~/work/corebench/polyspace-reports"
        ./run-polyspace.sh $1 $d ~/work/corebench/corerepo/ ~/work/corebench/corebench/ ~/work/corebench/polyspace-reports
    done
}
