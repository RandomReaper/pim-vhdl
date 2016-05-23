#!/bin/bash
#
# @brief	Find recursievly all Xilinx ISE project files and simulate them
#
# @param	none
# @env		verbose when VERBOSE=1
# @return	0 when all test are
#
# @usage	Go to the directory and call this script.
#
# * The test bench entity MUST be called 'tb'.
#
# * The end of a successful test bench must report the message
#	"PIM_VHDL_SIMULATION_DONE" with the severity note, example : 'assert false report "PIM_VHDL_SIMULATION_DONE" severity note;'
#
# * A warning in a test bench is considered a *failure* unless it is preceded by
# 	"PIM_VHDL_WARNING_EXPECTED", example: 'assert false report "PIM_VHDL_WARNING_EXPECTED, testing a flag" severity note'
#

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/env.sh

TEST=ghdl-sim-xise.sh
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
				echo warning expected/count:$WARNING_EXPECTED/$WARNING_COUNT
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
done <<< "$(find . -name '*.xise' -printf '%h\n' | sort)"

exit $RESULT