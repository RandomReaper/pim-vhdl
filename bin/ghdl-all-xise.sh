#!/bin/bash
#
# @brief	Find recursievly all Xilinx ISE project files and simulate them
#
# @param	none (= start in currrent dir) or starting directory
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

function do_test
{
	if [ -z "$dir" ]
	then
		return
	fi

	WARNING_EXPECTED=0
	WARNING_COUNT=0
	SUB_RESULT=2

	export USE_RESET

	printf "%-$LENGTH""s : " "$dir"

	while read line
	do
		if [ ! -z "$VERBOSE" ]
		then
			echo $line
		fi

		if echo $line | grep ':(assertion warning):' > /dev/null
		then
			((WARNING_COUNT++))
			if (( WARNING_EXPECTED != WARNING_COUNT))
			then
				echo warning rised before expected
				SUB_RESULT=1
			fi
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

	done <<< "$($TEST $dir 2>&1)"

	if (( SUB_RESULT == 0 ))
	then
		echo "success"
	else
		echo "FAILURE"
		RESULT=1
	fi
}

if [ $# -gt 0 ]
then
	cd $(readlink -m "$1")
fi

START_DIR=$PWD
TEST=ghdl-sim-xise.sh
HERE=$(echo "$PWD" | sed -e s~"$(git rev-parse --show-toplevel)"/~~)

# Get max length
LENGTH=0
while read dir
do
	if [ ${#dir} -gt "$LENGTH" ]
	then
		LENGTH=${#dir}
	fi
done <<< "$(find . -name '*.xise' -printf '%h\n' | sort)"

RESULT=0

echo "Running all 'tb' from $HERE directory"
while read dir
do
	do_test
done <<< "$(find . -name '*.xise' ! -exec grep -q "managed_tb\.vhd" {} \; -printf '%h\n' | sort)"
echo

for USE_RESET in 0 1
do
	if [ $USE_RESET -eq 1 ]
	then
		echo "Running all 'managed_tb' from $HERE directory with asynchronous reset"
	else
		echo "Running all 'managed_tb' from $HERE directory without reset"
	fi

	while read dir
	do
		do_test
	done <<< "$(find . -name '*.xise' -exec grep -q "managed_tb\.vhd" {} \; -printf '%h\n' | sort)"
	echo
done

cd $START_DIR

exit $RESULT