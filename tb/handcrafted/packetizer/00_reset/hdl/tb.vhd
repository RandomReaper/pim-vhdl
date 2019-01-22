-----------------------------------------------------------------------------
-- file			: tb.vhd
--
-- brief		: Test bench
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
generic
(
	g_parallel	: natural := 3
);
end tb;

architecture bhv of tb is
	constant bug_severity : severity_level := failure;

	signal reset			: std_ulogic;
	signal clock			: std_ulogic;
	signal stop				: std_ulogic;

	signal write			: std_ulogic;
	signal write_data		: std_ulogic_vector(7 downto 0);

	signal read_data		: std_ulogic_vector(7 downto 0);
	signal read				: std_ulogic;

	signal status_empty		: std_ulogic;
	signal status_full		: std_ulogic;
begin

	tb : process
	begin

	-----------------------------------------------------------------------------
	-- No reset
	-----------------------------------------------------------------------------
	stop			<= '0';
	reset			<= '0';

	write			<= '0';
	write_data		<= (others => '0');
	read			<= '0';

	wait until rising_edge(clock);
	wait until falling_edge(clock);

	assert (status_empty				= '1')			report "status_empty should be '1' and is " & std_ulogic'image(status_empty) severity bug_severity;
	assert (status_full					= '0')			report "status_full should be '0' and is " & std_ulogic'image(status_full) severity bug_severity;
	assert (read_data					= (read_data'range => 'U'))	report "read_data should be U" severity bug_severity;

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

	assert (status_empty				= '1')			report "status_empty should be '1' and is " & std_ulogic'image(status_empty) severity bug_severity;
	assert (status_full					= '0')			report "status_full should be '0' and is " & std_ulogic'image(status_full) severity bug_severity;
	assert (read_data					= (read_data'range => 'U'))	report "read_data should be U" severity bug_severity;

	wait until rising_edge(clock);
	wait until falling_edge(clock);

	-----------------------------------------------------------------------------
	-- End of test
	-----------------------------------------------------------------------------

	stop <= '1';

	wait;

	end process;

i_dut : entity work.packetizer
port map
(
	reset			=> reset,
	clock			=> clock,

	write			=> write,
	write_data		=> write_data,

	read_data		=> read_data,
	read			=> read,

	status_empty	=> status_empty,
	status_full		=> status_full
);

i_clock : entity work.clock_stop
port map
(
	frequency	=> 80.0e6,
	clock		=> clock,
	stop		=> stop
);

end bhv;
