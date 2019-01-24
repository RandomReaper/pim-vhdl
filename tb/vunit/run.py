#!/usr/bin/env python3
#############################################################################
## file			: run.py
##
## brief		: run vunit tests
## author(s)	: marc at pignat dot org
##
#############################################################################
## Copyright 2015-2019 Marc Pignat
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
## 		http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## See the License for the specific language governing permissions and
## limitations under the License.
#############################################################################

from os.path import dirname
from vunit import VUnit
import glob

# Initialize vunit using command line arguments
ui = VUnit.from_argv()

# Add vunit library
lib = ui.add_library("lib")

# Add all vhdl files from pim-vhdl
pim_lib = '../../hdl'
for filename in glob.iglob(pim_lib + '/**/*.vhd', recursive=True):
	lib.add_source_files(filename)

# Add all vhdl files from pim-vhdl boards
pim_boards = '../../board'
for filename in glob.iglob(pim_boards + '/**/*.vhd', recursive=True):
	lib.add_source_files(filename)

# Add all vhdl testbenshes from CWD and subdirectories
root = dirname(__file__)
for filename in sorted(glob.iglob(root + '/**/*.vhd', recursive=True)):
	lib.add_source_files(filename)


# TODO : add a caddy file for tb with generics

# tb named *_tbc should be run once with an asynchronous reset and once without
tbc = lib.get_test_benches("*_tbc", True)
for tb in tbc:
	tb.add_config("reset", generics=dict(g_reset_enable='true'))
	tb.add_config("no_reset", generics=dict(g_reset_enable='false'))

# Now run
ui.main()
