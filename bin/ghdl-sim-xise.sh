#!/bin/bash
#
# @param none (start in current dir) or staring dir
# @brief Simulate the entity 'tb' from a Xilinx ISE project.
#

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/env.sh

START_DIR=$PWD

if [ $# -gt 0 ]
then
	cd $(readlink -m "$1")
fi

files=()
while read line
do
	files+=("$line")
done <<< "$(cat *.xise | grep "FILE_VHDL" | grep "file xil_pn" | sed -e "s/    <file xil_pn:name=\"//" | sed -e "s/\" xil_pn:type=\"FILE_VHDL\">//" | sort) "

ghdl-sim.sh ${files[@]}

cd $START_DIR