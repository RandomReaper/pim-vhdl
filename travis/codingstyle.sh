#!/bin/bash

ORIG=$PWD
export PATH=$HOME/ghdl/bin:$PATH
export LD_LIBRARY_PATH=$HOME/lib:$LD_LIBRARY_PATH
source bin/env.sh
cd tb
NO_FAIL=1 codingstyle.sh
cd $ORIG