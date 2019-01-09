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
	TEST="cat $file | sed -e 's/--.*//' | grep -n '    '"
	if eval "$TEST" > /dev/null
	then
		>&2 echo "$file" : CodingStyle 4 space found, should be a TAB.
		>&2 eval "$TEST"
		>&2 echo
		RESULT=1
		if [ ! -z "$FIX" ]
		then
			$FIX "$file"
		fi
	fi
	TEST="cat $file | sed -e 's/--.*//' | grep -n -P ' \t'"
	if eval "$TEST" > /dev/null
	then
		>&2 echo "$file" : CodingStyle space followed by TAB.
		>&2 eval "$TEST"
		>&2 echo
		RESULT=1
		if [ ! -z "$FIX" ]
		then
			$FIX "$file"
		fi
	fi
	TEST="cat $file | grep -n ' $'"
	if eval "$TEST" > /dev/null
	then
		>&2 echo "$file" : CodingStyle leading space.
		>&2 eval "$TEST"
		>&2 echo
		RESULT=1
		if [ ! -z "$FIX" ]
		then
			$FIX "$file"
		fi
	fi
	TEST="cat $file | grep -n -P '\t$'"
	if eval "$TEST" > /dev/null
	then
		>&2 echo "$file" : CodingStyle leading TAB.
		>&2 eval "$TEST"
		>&2 echo
		RESULT=1
		if [ ! -z "$FIX" ]
		then
			$FIX "$file"
		fi
	fi
done <<< "$(find . -name '*.vhd' | sort)"

if [ ! -z "$NO_FAIL" ]
then
	exit 0
fi

exit $RESULT
