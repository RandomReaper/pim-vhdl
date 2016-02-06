#!/bin/bash
DIR=`mktemp -d`
GHDL="ghdl"
OPTIONS="--workdir=$DIR"

echo "workdir=$DIR"
cat project.xise | grep "FILE_VHDL" | grep "file xil_pn" | sed -e "s/    <file xil_pn:name=\"//" | sed -e "s/\" xil_pn:type=\"FILE_VHDL\">//" | while read line
do
	echo adding file "$line"
	$GHDL -i $OPTIONS "$line"
done

$GHDL -m $OPTIONS tb
$GHDL -e $OPTIONS tb
$GHDL -r $OPTIONS tb
#rm $DIR


