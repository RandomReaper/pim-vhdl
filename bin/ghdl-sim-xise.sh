#!/bin/bash
files=()
while read line
do
	files+=("$line")
done <<< "$(cat *.xise | grep "FILE_VHDL" | grep "file xil_pn" | sed -e "s/    <file xil_pn:name=\"//" | sed -e "s/\" xil_pn:type=\"FILE_VHDL\">//" | sort) "

ghdl-sim.sh ${files[@]}
