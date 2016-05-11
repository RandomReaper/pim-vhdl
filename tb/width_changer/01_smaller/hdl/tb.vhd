-----------------------------------------------------------------------------
-- file			: tb.vhd
--
-- brief		: Test bench for the with changer
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

entity tb is
end tb;

architecture bhv of tb is
	constant half_period : time := 0.5 ns;

	signal reset 				: std_ulogic;
	signal clock 				: std_ulogic;
	signal stop 				: std_ulogic;
	signal in_data				: std_ulogic_vector(11 downto 0);
	signal in_data_valid		: std_ulogic;
	signal in_data_ready		: std_ulogic;
	signal out_data				: std_ulogic_vector(3 downto 0);
	signal out_data_ready		: std_ulogic;
	signal out_data_valid		: std_ulogic;
begin


i_dut : entity work.width_changer
	port map
	(
	clock			=> clock,
	reset			=> reset,

	in_data			=> in_data,
	in_data_valid	=> in_data_valid,
	in_data_ready	=> in_data_ready,

	out_data		=> out_data,
	out_data_valid	=> out_data_valid,
	out_data_ready	=> out_data_ready
	);

i_clock: entity work.clock_stop
generic map
(
	frequency => 100.0e6
)
port map
(
	clock	=> clock,
	stop	=> stop
);

tb : process
	variable timeout : integer;
begin

	-----------------------------------------------------------------------------
	-- Full nice reset
	-----------------------------------------------------------------------------
	stop			<= '0';
	reset			<= '1';
	in_data			<= x"000";
	in_data_valid	<= '0';
	out_data_ready	<= '0';

	wait until falling_edge(clock);

	reset			<= '0';
	wait until rising_edge(clock);
	-----------------------------------------------------------------------------
	-- Verify all outputs after reset
	-----------------------------------------------------------------------------
	assert (out_data_valid			= '0')			report "widh_changer_smaller buggy !?!" severity warning;
	assert (in_data_ready			= '1')          report "widh_changer_smaller buggy !?!" severity warning;

	-----------------------------------------------------------------------------
	-- Test a read twice when empty
	-----------------------------------------------------------------------------
	--assert false									report "Testing read when empty, warning:status_read_error expected" severity note;

	in_data			<= x"123";
	in_data_valid	<= '1';
	out_data_ready	<= '0';

	wait until rising_edge(clock);
	wait until falling_edge(clock);
	in_data_valid	<= '0';
	assert (out_data_valid			= '0')			report "widh_changer_smaller buggy !?!" severity warning;
	assert (in_data_ready			= '0')          report "widh_changer_smaller buggy !?!" severity warning;


	wait until falling_edge(clock);
	out_data_ready	<= '1';

	wait until rising_edge(clock);
	assert (out_data_valid			= '1')			report "widh_changer_smaller buggy !?!" severity warning;
	assert (out_data				= x"1")			report "widh_changer_smaller buggy !?!" severity warning;
	assert (in_data_ready			= '0')          report "widh_changer_smaller buggy !?!" severity warning;


	wait until rising_edge(clock);
	assert (out_data_valid			= '1')			report "widh_changer_smaller buggy !?!" severity warning;
	assert (out_data				= x"2")			report "widh_changer_smaller buggy !?!" severity warning;
	assert (in_data_ready			= '0')          report "widh_changer_smaller buggy !?!" severity warning;

	wait until rising_edge(clock);
	assert (out_data_valid			= '1')			report "widh_changer_smaller buggy !?!" severity warning;
	assert (out_data				= x"3")			report "widh_changer_smaller buggy !?!" severity warning;
	assert (in_data_ready			= '0')          report "widh_changer_smaller buggy !?!" severity warning;



	-----------------------------------------------------------------------------
	-- End of test
	-----------------------------------------------------------------------------

	stop			<= '1';
	wait;

end process;

end bhv;

