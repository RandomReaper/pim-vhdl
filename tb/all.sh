#!/bin/bash
TEST=`readlink -m ./ghdl-sim.sh`
BASE=`readlink -m .`

find . -name 'project.xise' -print | sed -e 's/project.xise//' | while read dir; do
	echo "Processing dir '$dir'"
	cd $dir
	$TEST
	cd $BASE
done
