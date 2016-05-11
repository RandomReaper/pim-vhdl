#!/bin/bash
DIR=$(mktemp -d)
GHDL="ghdl"
OPTIONS="--workdir=$DIR"

if uname | grep CYGWIN > /dev/null
then
	OPTIONS="--workdir=$(cygpath -w $DIR)"
	echo $OPTIONS
fi

cat project.xise | grep "FILE_VHDL" | grep "file xil_pn" | sed -e "s/    <file xil_pn:name=\"//" | sed -e "s/\" xil_pn:type=\"FILE_VHDL\">//" | while read line
do
	$GHDL -i $OPTIONS "$line"
done

$GHDL -m $OPTIONS tb
$GHDL -e $OPTIONS tb
$GHDL -r $OPTIONS tb --ieee-asserts=disable-at-0
rm -r $DIR

