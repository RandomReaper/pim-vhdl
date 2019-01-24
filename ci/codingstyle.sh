#!/bin/bash
export PATH=$HOME/ghdl/bin:$PATH
export LD_LIBRARY_PATH=$HOME/lib:$LD_LIBRARY_PATH
source bin/env.sh
pushd tb
NO_FAIL=1 codingstyle.sh
popd
