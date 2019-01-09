#!/bin/bash

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/env.sh


if [ $# -gt 0 ]
then
	cd "$(readlink -m "$1")"
fi

RESULT=0

if ! ghdl-all-unmanaged-xise.sh; then
	RESULT=1
fi

if ! ghdl-all-managed_reset-xise.sh; then
	RESULT=1
fi

if ! ghdl-all-managed_no_reset-xise.sh; then
	RESULT=1
fi

exit "$RESULT"