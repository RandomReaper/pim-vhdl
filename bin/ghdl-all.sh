#!/bin/bash
TEST=ghdl-sim.sh
BASE=$(readlink -m .)
RESULT=0
while read dir
do
	cd $dir

	WARNING_EXPECTED=0
	WARNING_COUNT=0
	SUB_RESULT=2
	while read line
	do
		if [ ! -z "$VERBOSE" ]
		then
			echo $line
		fi

		if echo $line | grep ':(assertion warning):' > /dev/null
		then
			((WARNING_COUNT++))
		fi

		if echo $line | grep ':(assertion note): PIM_VHDL_WARNING_EXPECTED' > /dev/null
		then
			((WARNING_EXPECTED++))
		fi

		if echo $line | grep 'PIM_VHDL_SIMULATION_DONE' > /dev/null
		then
			SUB_RESULT=0
			if (( WARNING_EXPECTED != WARNING_COUNT))
			then
				SUB_RESULT=1
			fi

			if [ ! -z "$VERBOSE" ]
			then
				echo WARNING_COUNT:$WARNING_COUNT
				echo WARNING_EXPECTED:$WARNING_EXPECTED
			fi
		fi

	done <<< "$($TEST 2>&1)"

	if (( SUB_RESULT == 0 ))
	then
		echo "success : $dir"
	else
		echo "FAILURE : $dir"
		RESULT=1
	fi
	cd $BASE
done <<< "$(find . -name 'project.xise' -print | sed -e 's/project.xise//')"

exit $RESULT