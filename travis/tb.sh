#!/bin/bash

ORIG=$PWD
export PATH=$HOME/ghdl/bin:$PATH
export LD_LIBRARY_PATH=$HOME/lib:$LD_LIBRARY_PATH
source bin/env.sh
cd tb
ghdl-all.sh
cd $ORIG
