-----------------------------------------------------------------------------
-- file			: tb.vhd
--
-- brief		: Test bench for the with changer
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

entity tb is
end entity;

architecture bhv of tb is
	constant bug_severity : severity_level := failure;

	constant half_period : time := 0.5 ns;

	signal reset		: std_ulogic;
	signal clock		: std_ulogic;
	signal stop			: std_ulogic;
	signal in_data		: std_ulogic_vector(11 downto 0);
	signal in_write		: std_ulogic;
	signal in_ready		: std_ulogic;
	signal out_data		: std_ulogic_vector(3 downto 0);
	signal out_ready	: std_ulogic;
	signal out_write	: std_ulogic;
begin


i_dut : entity work.width_changer
	port map
	(
	clock		=> clock,
	reset		=> reset,

	in_data		=> in_data,
	in_write	=> in_write,
	in_ready	=> in_ready,

	out_data	=> out_data,
	out_write	=> out_write,
	out_ready	=> out_ready
	);

i_clock: entity work.clock_stop
port map
(
	frequency	=> 100.0e6,
	clock		=> clock,
	stop		=> stop
);

tb : process
	variable timeout : integer;
begin

	-----------------------------------------------------------------------------
	-- Full nice reset
	-----------------------------------------------------------------------------
	stop		<= '0';
	reset		<= '1';
	in_data		<= (others => '-');
	in_write	<= '0';
	out_ready	<= '0';

	wait until falling_edge(clock);

	reset		<= '0';
	wait until rising_edge(clock);
	-----------------------------------------------------------------------------
	-- Verify all outputs after reset
	-----------------------------------------------------------------------------
	assert (out_write			= '0')			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (in_ready			= '1')			report "widh_changer_smaller buggy !?!" severity bug_severity;

	-----------------------------------------------------------------------------
	-- Test a write with output not ready
	-----------------------------------------------------------------------------
	--assert false									report "Testing read when empty, warning:status_read_error expected" severity note;

	wait until falling_edge(clock);

	in_data		<= x"123";
	in_write	<= '1';
	out_ready	<= '0';

	wait until rising_edge(clock);
	wait until falling_edge(clock);
	in_data		<= (others => '-');
	in_write	<= '0';
	assert (out_write			= '0')			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (in_ready			= '0')			report "widh_changer_smaller buggy !?!" severity bug_severity;


	wait until falling_edge(clock);
	out_ready	<= '1';

	wait until rising_edge(clock);
	assert (out_write			= '1')			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (out_data			= x"1")			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (in_ready			= '0')			report "widh_changer_smaller buggy !?!" severity bug_severity;


	wait until rising_edge(clock);
	assert (out_write			= '1')			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (out_data			= x"2")			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (in_ready			= '0')			report "widh_changer_smaller buggy !?!" severity bug_severity;

	wait until rising_edge(clock);
	assert (out_write			= '1')			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (out_data			= x"3")			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (in_ready			= '1')			report "widh_changer_smaller buggy !?!" severity bug_severity;

	-----------------------------------------------------------------------------
	-- Test two consecutive writes with output ready
	-----------------------------------------------------------------------------
	wait until falling_edge(clock);
	in_data		<= (others => '-');
	in_write	<= '0';
	out_ready	<= '1';

	wait until rising_edge(clock);
	assert (out_write			= '0')			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (in_ready			= '1')			report "widh_changer_smaller buggy !?!" severity bug_severity;

	wait until falling_edge(clock);
	in_data		<= x"456";
	in_write	<= '1';
	out_ready	<= '1';

	wait until falling_edge(clock);
	in_data		<= (others => '-');
	in_write	<= '0';

	wait until rising_edge(clock);
	assert (out_write			= '1')			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (out_data			= x"4")			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (in_ready			= '0')			report "widh_changer_smaller buggy !?!" severity bug_severity;

	wait until rising_edge(clock);
	assert (out_write			= '1')			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (out_data			= x"5")			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (in_ready			= '0')			report "widh_changer_smaller buggy !?!" severity bug_severity;

	wait until falling_edge(clock);
	in_data		<= x"678";
	in_write	<= '1';
	out_ready	<= '1';

	wait until rising_edge(clock);
	assert (out_write			= '1')			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (out_data			= x"6")			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (in_ready			= '1')			report "widh_changer_smaller buggy !?!" severity bug_severity;

	wait until falling_edge(clock);
	in_data		<= (others => '-');
	in_write	<= '0';

	wait until rising_edge(clock);
	assert (out_write			= '1')			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (out_data			= x"6")			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (in_ready			= '0')			report "widh_changer_smaller buggy !?!" severity bug_severity;

	wait until rising_edge(clock);
	assert (out_write			= '1')			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (out_data			= x"7")			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (in_ready			= '0')			report "widh_changer_smaller buggy !?!" severity bug_severity;

	wait until rising_edge(clock);
	assert (out_write			= '1')			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (out_data			= x"8")			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (in_ready			= '1')			report "widh_changer_smaller buggy !?!" severity bug_severity;

	wait until rising_edge(clock);
	assert (out_write			= '0')			report "widh_changer_smaller buggy !?!" severity bug_severity;
	assert (in_ready			= '1')			report "widh_changer_smaller buggy !?!" severity bug_severity;

	-----------------------------------------------------------------------------
	-- End of test
	-----------------------------------------------------------------------------
	wait until rising_edge(clock);

	stop			<= '1';
	wait;

end process;

end architecture;
