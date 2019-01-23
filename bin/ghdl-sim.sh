#!/bin/bash
#
# @brief Simulate the 'tb' entity using .vhdl files provided as argument
#
#

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/env.sh

if [[ $# -eq 0 ]] ; then
	echo 'no args, nothing to do'
	exit 1
fi

DIR=$(mktemp -d)
GHDL="ghdl"
OPTIONS="--workdir=$DIR"

if uname | grep CYGWIN > /dev/null
then
	OPTIONS="--workdir=$(cygpath -w "$DIR")"
	echo "$OPTIONS"
fi

MANAGED=0
for file in "$@"
do
	if [ ! -z "$VERBOSE" ]
	then
		echo adding "$file"
	fi
	$GHDL -i "$OPTIONS" "$file"
	if grep -q 'managed_tbc' "$file"
	then
		MANAGED=1
	fi
done

if [ -z "$USE_RESET" ]
then
	USE_RESET=0
fi

ARCH=""
if [ "$MANAGED" -eq 1 ]
then
	if [ "$USE_RESET" -eq 1 ]
	then
		ARCH="bhv_with_reset"
	else
		ARCH="bhv_without_reset"
	fi
fi

$GHDL -m "$OPTIONS" tb $ARCH
$GHDL -e "$OPTIONS" tb $ARCH
$GHDL -r "$OPTIONS" tb $ARCH --ieee-asserts=disable-at-0
rm -r "$DIR"
