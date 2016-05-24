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
end tb;

architecture bhv of tb is
	constant bug_severity : severity_level := failure;

	constant g_depth_log2 : integer := 2;
	constant g_depth : integer := 2**g_depth_log2;

	signal reset 				: std_ulogic;
	signal clock 				: std_ulogic;
	signal stop 				: std_ulogic;
	signal reset_sync			: std_ulogic;
	signal write				: std_ulogic;
	signal write_data			: std_ulogic_vector(7 downto 0);
	signal read					: std_ulogic;
	signal read_data			: std_ulogic_vector(7 downto 0);
	signal status_full			: std_ulogic;
	signal status_empty			: std_ulogic;
	signal status_write_error	: std_ulogic;
	signal status_read_error	: std_ulogic;
	signal free_int				: std_ulogic_vector(g_depth_log2 downto 0);
	signal used_int				: std_ulogic_vector(g_depth_log2 downto 0);

	signal free : integer;
	signal used : integer;
begin

	free <= to_integer(unsigned(free_int));
	used <= to_integer(unsigned(used_int));

	tb : process
	begin

	-----------------------------------------------------------------------------
	-- No reset
	-----------------------------------------------------------------------------
	stop		<= '0';
	reset		<= '0';
	reset_sync	<= '0';
	read		<= '0';
	write		<= '0';

	wait until rising_edge(clock);
	wait until falling_edge(clock);

	assert (free					= g_depth)		report "fifo buggy !?!" severity bug_severity;
	assert (used					= 0)			report "fifo buggy !?!" severity bug_severity;
	assert (status_empty			= '1')			report "empty should be '1' and is " & std_ulogic'image(status_empty) severity bug_severity;
	assert (status_full				= '0')			report "status_full should be '1' and is " & std_ulogic'image(status_full) severity bug_severity;
	assert (status_read_error		= '0')			report "status_read_error should be '1' and is " & std_ulogic'image(status_read_error) severity bug_severity;
	assert (status_write_error		= '0')			report "status_write_error should be '1' and is " & std_ulogic'image(status_write_error) severity bug_severity;

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

	assert (free					= g_depth)		report "fifo buggy !?!" severity bug_severity;
	assert (used					= 0)			report "fifo buggy !?!" severity bug_severity;
	assert (status_empty			= '1')			report "empty should be '1' and is " & std_ulogic'image(status_empty) severity bug_severity;
	assert (status_full				= '0')			report "status_full should be '1' and is " & std_ulogic'image(status_full) severity bug_severity;
	assert (status_read_error		= '0')			report "status_read_error should be '1' and is " & std_ulogic'image(status_read_error) severity bug_severity;
	assert (status_write_error		= '0')			report "status_write_error should be '1' and is " & std_ulogic'image(status_write_error) severity bug_severity;

	wait until rising_edge(clock);
	wait until falling_edge(clock);

	-----------------------------------------------------------------------------
	-- Sync reset
	-----------------------------------------------------------------------------

	reset_sync	<= '1';
	wait until rising_edge(clock);
	reset_sync	<= '0';
	wait until rising_edge(clock);
	wait until falling_edge(clock);

	assert (free					= g_depth)		report "fifo buggy !?!" severity bug_severity;
	assert (used					= 0)			report "fifo buggy !?!" severity bug_severity;
	assert (status_empty			= '1')			report "empty should be '1' and is " & std_ulogic'image(status_empty) severity bug_severity;
	assert (status_full				= '0')			report "status_full should be '1' and is " & std_ulogic'image(status_full) severity bug_severity;
	assert (status_read_error		= '0')			report "status_read_error should be '1' and is " & std_ulogic'image(status_read_error) severity bug_severity;
	assert (status_write_error		= '0')			report "status_write_error should be '1' and is " & std_ulogic'image(status_write_error) severity bug_severity;

	-----------------------------------------------------------------------------
	-- End of test
	-----------------------------------------------------------------------------

	wait until rising_edge(clock);
	wait until falling_edge(clock);

	stop <= '1';

	wait;

	end process;

i_fifo : entity work.fifo
	generic map
	(
		g_depth_log2 => g_depth_log2
	)
	port map
	(
		reset 				=> reset,
		clock 				=> clock,
		reset_sync			=> reset_sync,
		write				=> write,
		write_data			=> write_data,
		read				=> read,
		read_data			=> read_data,
		status_full			=> status_full,
		status_empty		=> status_empty,
		status_write_error	=> status_write_error,
		status_read_error	=> status_read_error,
		free 				=> free_int,
		used 				=> used_int
	);

i_clock : entity work.clock_stop
generic map
(
	frequency	=> 80.0e6
)
port map
(
	clock		=> clock,
	stop		=> stop
);

end bhv;
