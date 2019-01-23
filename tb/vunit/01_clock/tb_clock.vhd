-----------------------------------------------------------------------------
-- brief		: vunit test for clock
-- author(s)	: marc at pignat dot org
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

entity tb_clock_00 is
	generic
	(
		runner_cfg	: string;
		frequency	: real	:= 1.0e6
	);
end entity;

architecture bhv of tb_clock_00 is
	signal clock		: std_ulogic;
begin
	main : process
	begin
		test_runner_setup(runner, runner_cfg);

		wait until rising_edge(clock);
		wait until rising_edge(clock);
		wait until rising_edge(clock);
		wait until rising_edge(clock);

		test_runner_cleanup(runner);
	end process;

	i_clock : entity work.clock
	generic map
	(
		frequency	=> frequency
	)
	port map
	(
		clock		=> clock
	);

end architecture;