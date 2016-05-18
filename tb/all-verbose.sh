#!/bin/bash
exit 0
set
echo $PATH
TEST=ghdl-sim.sh
BASE=$(readlink -m $PWD)
RESULT=0
while read dir
do
	cd $dir
	$TEST
	cd $BASE
done <<< "$(find . -name 'project.xise' -print | sed -e 's/project.xise//')"

exit 0