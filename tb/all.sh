#!/bin/bash
TEST=$(readlink -m ./ghdl-sim.sh)
BASE=$(readlink -m .)

find . -name 'project.xise' -print | sed -e 's/project.xise//' | while read dir; do
	cd $dir
	if $TEST 2>&1 | grep 'Simulation Done' > /dev/null
	then
		echo "success : $dir"
	else
		echo "FAILURE : $dir"
	fi
	cd $BASE
done
