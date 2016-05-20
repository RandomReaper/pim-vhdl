#!/bin/bash
#
# @brief Simulate the 'tb' entity using .vhdl files provided as argument
#
#

if [[ $# -eq 0 ]] ; then
	echo 'no args, nothing to do'
	exit 1
fi

DIR=$(mktemp -d)
GHDL="ghdl"
OPTIONS="--workdir=$DIR"

if uname | grep CYGWIN > /dev/null
then
	OPTIONS="--workdir=$(cygpath -w $DIR)"
	echo $OPTIONS
fi

for file in "$@"
do
	if [ ! -z "$VERBOSE" ]
	then
		echo adding $file
	fi
	$GHDL -i $OPTIONS "$file"
done

$GHDL -m $OPTIONS tb
$GHDL -e $OPTIONS tb
$GHDL -r $OPTIONS tb --ieee-asserts=disable-at-0
rm -r $DIR

