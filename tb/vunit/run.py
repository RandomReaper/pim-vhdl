#!/usr/bin/env python3
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2018, Lars Asplund lars.anders.asplund@gmail.com

from os.path import join, dirname
from vunit import VUnit
import glob

pim_lib = '../../hdl'
root = dirname(__file__)

ui = VUnit.from_argv()
lib = ui.add_library("lib")
for filename in glob.iglob(root + '/**/*.vhd', recursive=True):
	lib.add_source_files(filename)

for filename in glob.iglob(pim_lib + '/**/*.vhd', recursive=True):
	lib.add_source_files(filename)

mtb = lib.get_test_benches("*tbc*", True)
for tb in mtb:
	tb.add_config("with_reset", generics=dict(g_reset_enable='true'))
	tb.add_config("without_reset", generics=dict(g_reset_enable='false'))


#tb_with_lower_level_control = lib.entity("tb_with_lower_level_control")
#tb_with_lower_level_control.scan_tests_from_file(join(root, "test_control.vhd"))
ui.main()
