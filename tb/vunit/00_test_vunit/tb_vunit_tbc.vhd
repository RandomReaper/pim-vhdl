-----------------------------------------------------------------------------
-- file			: tb_vunit_tbc.vhd
--
-- brief		: Example vunit test bench using reset AND not using reset
-- author(s)	: marc at pignat dot org
-----------------------------------------------------------------------------
-- Copyright 2015,2016 Marc Pignat
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

entity tb_vunit_tbc is
	generic
	(
		runner_cfg		: string;
		g_reset_enable	: boolean := false
	);
	
end entity;

architecture tb of tb_vunit_tbc is
	signal clock		: std_ulogic;
	signal reset		: std_ulogic;
	signal done			: std_ulogic;
begin
	i_vunit_tbc: entity work.vunit_tbc
	generic map
	(
		g_frequency		=> 1.0e6,
		g_runner_cfg	=> runner_cfg,
		g_reset_enable	=> g_reset_enable
	)
	port map
	(
		clock		=> clock,
		reset		=> reset,
		done		=> done
	);

	tb : process
	begin
		done <= '0';
		wait until reset = '0';

		wait until rising_edge(clock);
		wait until rising_edge(clock);
		wait until rising_edge(clock);
		wait until rising_edge(clock);
		
		done <= '1';
		wait;
	end process;
end architecture;

