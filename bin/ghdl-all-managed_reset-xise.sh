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
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/_run_tb.sh

if [ $# -gt 0 ]
then
	cd "$(readlink -m "$1")"
fi

START_DIR=$PWD
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

export USE_RESET=1
echo "Running all 'managed_tbc' from $HERE directory with asynchronous reset"

while read dir
do
	if ! run_tb "$dir"; then
		RESULT=1
	fi
done <<< "$(find . -name '*.xise' -exec grep -q "managed_tbc\.vhd" {} \; -printf '%h\n' | sort)"
echo

cd "$START_DIR"

exit "$RESULT"