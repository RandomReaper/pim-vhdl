#!/bin/bash
TEST=ghdl-sim.sh
BASE=$(readlink -m .)
RESULT=0
while read dir
do
	cd $dir
	$TEST
	cd $BASE
done <<< "$(find . -name 'project.xise' -print | sed -e 's/project.xise//')"

exit 0