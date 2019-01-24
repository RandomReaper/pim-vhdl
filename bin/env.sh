#!/bin/bash
#
# @brief	Add the directory containing this file to the PATH
#
# @usage	source this file from anywhere
#

# Make sure this script is sourced
if [ "$0" = "$BASH_SOURCE" ]; then
    echo "Error: Script must be sourced"
    exit 1
fi

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export PATH=$CURRENT_DIR:$PATH
if ! ghdl -v >/dev/null 2>&1
then
	if ! [ -e "$CURRENT_DIR"/.cache/ghdl/bin/ghdl ] || ! [ -e "$HOME"/lib/libgnat-4.6.so.1 ]
	then
		>&2 echo '***************************************************************************'
		>&2 echo "*** WARNING: ghdl not found, trying to install it in $CURRENT_DIR/.cache"
		>&2 echo '***************************************************************************'
		HOME="$CURRENT_DIR"/.cache "$CURRENT_DIR"/../ci/travis-deps.sh || exit 1
	fi

	export PATH=$CURRENT_DIR/.cache/ghdl/bin:$PATH

	if uname | grep Linux > /dev/null
	then
		export LD_LIBRARY_PATH=$CURRENT_DIR/.cache/lib:$LD_LIBRARY_PATH
	fi

	echo LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
	if ! ghdl -v
	then
		>&2 echo '***************************************************************************'
		>&2 echo '*** WARNING: ghdl cannot be run'
		>&2 echo '***************************************************************************'
		exit 2
	fi
fi
