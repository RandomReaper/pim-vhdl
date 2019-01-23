-----------------------------------------------------------------------------
-- file			: vunit_tbc.vhd
--
-- brief		: vunit_tbc vunit compatible test bench controller
-- author(s)	: marc at pignat dot org
--
-- This entity runs a vunit tb, with clock and optional asynchronous reset.
-- The reset feature is selected by the generic g_reset_enable
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

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

library vunit_lib;
	context vunit_lib.vunit_context;

entity vunit_tbc is
	generic
	(
		g_runner_cfg	: string;
		g_frequency		: real	:= 1.0e6;
		g_reset_enable	: boolean := false
	);
	port
	(
		done		: in	std_ulogic;
		clock		: out	std_ulogic;
		reset		: out	std_ulogic
	);
end vunit_tbc;

architecture bhv of vunit_tbc is
	signal reset_int	: std_ulogic := '0';
begin

	i_clock : entity work.clock
	generic map
	(
		frequency	=> g_frequency
	)
	port map
	(
		clock		=> clock
	);

	i_reset : entity work.reset
	port map
	(
		reset		=> reset_int,
		clock		=> clock
	);

	main : process
	begin
		test_runner_setup(runner, g_runner_cfg);
		report "test started";
		report g_runner_cfg;
		wait for 10 ns;
		wait until rising_edge(done);
		report "test done";
		test_runner_cleanup(runner);
	end process;

	reset <= reset_int when g_reset_enable else '0';

end architecture bhv;
