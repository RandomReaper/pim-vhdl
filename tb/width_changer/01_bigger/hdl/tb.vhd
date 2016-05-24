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
	constant bug_severity : severity_level := failure;

	constant half_period : time := 0.5 ns;

	signal reset 		: std_ulogic;
	signal clock 		: std_ulogic;
	signal stop 		: std_ulogic;
	signal in_data		: std_ulogic_vector(3 downto 0);
	signal in_write		: std_ulogic;
	signal in_ready		: std_ulogic;
	signal out_data		: std_ulogic_vector(11 downto 0);
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
	-- No reset
	-----------------------------------------------------------------------------
	stop		<= '0';
	reset		<= '0';

	wait until rising_edge(clock);
	wait until falling_edge(clock);

	assert (in_ready				= '0')			report "in_ready should be '0' and is " & std_ulogic'image(in_ready) severity bug_severity;
	assert (out_write				= '0')			report "out_valid should be '0' and is " & std_ulogic'image(out_valid) severity bug_severity;
	assert (out_data	= (out_data'range => '-'))	report "out_data should be all -" severity bug_severity;

	wait until rising_edge(clock);
	wait until falling_edge(clock);

	-----------------------------------------------------------------------------
	-- Async reset
	-----------------------------------------------------------------------------

	reset		<= '1';
	wait until falling_edge(clock);
	wait until falling_edge(clock);
	reset		<= '0';
	wait until falling_edge(clock);

	assert (in_ready				= '0')			report "in_ready should be '0' and is " & std_ulogic'image(in_ready) severity bug_severity;
	assert (out_write				= '0')			report "out_valid should be '0' and is " & std_ulogic'image(out_valid) severity bug_severity;
	assert (out_data	= (out_data'range => '-'))	report "out_data should be all -" severity bug_severity;

	wait until rising_edge(clock);
	wait until falling_edge(clock);

	-----------------------------------------------------------------------------
	-- End of test
	-----------------------------------------------------------------------------

	stop <= '1';

	wait;

end process;

end bhv;

