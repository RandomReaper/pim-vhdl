#!/bin/bash
TEST=ghdl-sim.sh
BASE=$(readlink -m .)
RESULT=0
while read dir
do
	cd $dir
	if $TEST 2>&1 | grep 'Simulation Done' > /dev/null
	then
		echo "success : $dir"
	else
		echo "FAILURE : $dir"
		RESULT=1
	fi
	cd $BASE
done <<< "$(find . -name 'project.xise' -print | sed -e 's/project.xise//')"

exit $RESULT