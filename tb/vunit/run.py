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

from os.path import join, dirname
from vunit import VUnit
import glob

pim_lib = '../../hdl'
root = dirname(__file__)

ui = VUnit.from_argv()
lib = ui.add_library("lib")
for filename in sorted(glob.iglob(root + '/**/*.vhd', recursive=True)):
	lib.add_source_files(filename)

for filename in glob.iglob(pim_lib + '/**/*.vhd', recursive=True):
	lib.add_source_files(filename)

# TODO : add a caddy file for tb with generics

tbc = lib.get_test_benches("*tbc", True)
for tb in tbc:
	tb.add_config("reset", generics=dict(g_reset_enable='true'))
	tb.add_config("no_reset", generics=dict(g_reset_enable='false'))

ui.main()
