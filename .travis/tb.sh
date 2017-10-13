#!/bin/bash

ORIG=$PWD
export PATH=$HOME/ghdl/bin:$PATH
export LD_LIBRARY_PATH=$HOME/lib:$LD_LIBRARY_PATH
source bin/env.sh
RESULT=$?

if [ $RESULT -ne 0 ]; then
    echo "script failed, aborting"
fi


cd tb
all.sh
RESULT=$?
cd $ORIG
exit $RESULT
