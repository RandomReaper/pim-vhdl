#!/bin/bash
#
# @brief	Find recursievly all vhdl files and do some basic coding style check
#
# @env		NO_FAIL
# @return	0 when all test are successful, or when NO_FAIL=1
#
# @usage	Go to the directory and call this script.
#

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/env.sh

RESULT=0
while read file
do
	if cat $file | grep "    " | grep -v "\-\-" 2>&1 > /dev/null
	then
		echo CodingStyle:$file:4 space found, should be a TAB.
		RESULT=1
		if [ ! -z "$FIX" ]
		then
			$FIX $file
		fi
	fi
done <<< "$(find . -name '*.vhd' | sort)"

if [ ! -z "$NO_FAIL" ]
then
	exit 0
fi

exit $RESULT
