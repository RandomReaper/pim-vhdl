#!/bin/bash

ORIG=$PWD
source bin/env.sh
RESULT=$?

if [ $RESULT -ne 0 ]; then
    echo "script failed, aborting"
fi


cd tb/handcrafted
ghdl-all-managed_no_reset-xise.sh
RESULT=$?
cd "$ORIG"
exit $RESULT
