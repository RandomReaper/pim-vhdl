-----------------------------------------------------------------------------
-- brief		: vunit should be installed and working
-- author(s)	: marc at pignat dot org
--
-- This is an example testbench using the vunit_tbc block, this block enable
-- the same testbench to be run with AND without reset.
--
-----------------------------------------------------------------------------
-- Copyright 2015-2019 Marc Pignat
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- 		http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- See the License for the specific language governing permissions and
-- limitations under the License.
-----------------------------------------------------------------------------

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_vunit_00 is
	generic (runner_cfg : string);
end entity;

architecture bhv of tb_vunit_00 is
begin
	main : process
	begin
		test_runner_setup(runner, runner_cfg);
		report "vunit install test";
		test_runner_cleanup(runner); -- Simulation ends here
	end process;
end architecture;

