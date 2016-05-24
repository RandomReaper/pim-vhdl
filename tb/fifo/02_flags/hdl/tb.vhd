-----------------------------------------------------------------------------
-- file			: tb.vhd
--
-- brief		: Test bench for the fifo (flags and free/used outputs).
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
	constant half_period : time := 0.5 ns;

	signal reset 				: std_ulogic;
	signal clock 				: std_ulogic;
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

	i_dut : entity work.fifo
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

	tb : process
	begin

	-----------------------------------------------------------------------------
	-- Full nice reset
	-----------------------------------------------------------------------------

	reset			<= '1';
	reset_sync		<= '0';
	read			<= '0';
	write			<= '0';
	write_data		<= x"00";
	clock <= '0';

	wait for half_period; wait for half_period;

	reset			<= '0';
	-----------------------------------------------------------------------------
	-- Verify all outputs after reset
	-----------------------------------------------------------------------------
	assert (free					= g_depth)		report "fifo buggy !?!" severity bug_severity;
	assert (used					= 0)			report "fifo buggy !?!" severity bug_severity;
	assert (status_empty			= '1')			report "fifo buggy !?!" severity bug_severity;
	assert (status_full				= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_read_error		= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_write_error		= '0')			report "fifo buggy !?!" severity bug_severity;

	-----------------------------------------------------------------------------
	-- Test a read twice when empty
	-----------------------------------------------------------------------------
	assert false									report "PIM_VHDL_WARNING_EXPECTED: Testing read when empty:status_read_error expected" severity note;

	read <= '1';
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	read <= '0';

	assert (free					= g_depth)		report "fifo buggy !?!" severity bug_severity;
	assert (used					= 0)			report "fifo buggy !?!" severity bug_severity;
	assert (status_empty			= '1')			report "fifo buggy !?!" severity bug_severity;
	assert (status_full				= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_read_error		= '1')			report "fifo buggy !?!" severity bug_severity;
	assert (status_write_error		= '0')			report "fifo buggy !?!" severity bug_severity;

	assert false									report "PIM_VHDL_WARNING_EXPECTED: Testing read when empty:status_read_error expected" severity note;

	read <= '1';
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	read <= '0';

	assert (free					= g_depth)		report "fifo buggy !?!" severity bug_severity;
	assert (used					= 0)			report "fifo buggy !?!" severity bug_severity;
	assert (status_empty			= '1')			report "fifo buggy !?!" severity bug_severity;
	assert (status_full				= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_read_error		= '1')			report "fifo buggy !?!" severity bug_severity;
	assert (status_write_error		= '0')			report "fifo buggy !?!" severity bug_severity;

	-----------------------------------------------------------------------------
	-- Test a write
	-----------------------------------------------------------------------------

	write <= '1';
	write_data <= x"55";
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	write_data <= x"00";
	write <= '0';

	assert (free					= g_depth-1)	report "fifo buggy !?!" severity bug_severity;
	assert (used					= 1)			report "fifo buggy !?!" severity bug_severity;
	assert (status_empty			= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_full				= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_read_error		= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_write_error		= '0')			report "fifo buggy !?!" severity bug_severity;

	-----------------------------------------------------------------------------
	-- Test a simultaneous read/write with only one data in the fifo, should work
	-----------------------------------------------------------------------------
	write <= '1';
	read <= '1';
	write_data <= x"aa";
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	write_data <= x"00";
	write <= '0';
	read <= '0';

	assert (free					= g_depth-1)	report "fifo buggy !?!" severity bug_severity;
	assert (used					= 1)			report "fifo buggy !?!" severity bug_severity;
	assert (status_empty			= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_full				= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_read_error		= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_write_error		= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (read_data				= x"55")		report "fifo buggy !?!" severity bug_severity;

	-----------------------------------------------------------------------------
	-- Test read back
	-----------------------------------------------------------------------------
	read <= '1';
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	read <= '0';

	assert (free					= g_depth)		report "fifo buggy !?!" severity bug_severity;
	assert (used					= 0)			report "fifo buggy !?!" severity bug_severity;
	assert (status_empty			= '1')			report "fifo buggy !?!" severity bug_severity;
	assert (status_full				= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_read_error		= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_write_error		= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (read_data				= x"aa")		report "fifo buggy !?!" severity bug_severity;

	-----------------------------------------------------------------------------
	-- Test synchronous reset
	-----------------------------------------------------------------------------
	write <= '1';
	write_data <= x"55";
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	write_data <= x"00";
	write <= '0';
	reset_sync		<= '1';

	-- should not reset before clock !
	assert (free					= g_depth-1)	report "fifo buggy !?!" severity bug_severity;
	assert (used					= 1)			report "fifo buggy !?!" severity bug_severity;
	assert (status_empty			= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_full				= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_read_error		= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_write_error		= '0')			report "fifo buggy !?!" severity bug_severity;

	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	reset_sync		<= '0';
	-- Now should be reset
	assert (free					= g_depth)		report "fifo buggy !?!" severity bug_severity;
	assert (used					= 0)			report "fifo buggy !?!" severity bug_severity;
	assert (status_empty			= '1')			report "fifo buggy !?!" severity bug_severity;
	assert (status_full				= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_read_error		= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_write_error		= '0')			report "fifo buggy !?!" severity bug_severity;

	-----------------------------------------------------------------------------
	-- Test a simultaneous read/write while empty, (only read should fail)
	-----------------------------------------------------------------------------
	assert false									report "PIM_VHDL_WARNING_EXPECTED: Testing read/write while empty:status_read_error expected" severity note;

	write <= '1';
	read <= '1';
	write_data <= x"11";
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	write_data <= x"00";
	write <= '0';
	read <= '0';

	assert (free					= g_depth-1)	report "fifo buggy !?!" severity bug_severity;
	assert (used					= 1)			report "fifo buggy !?!" severity bug_severity;
	assert (status_empty			= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_full				= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_read_error		= '1')			report "fifo buggy !?!" severity bug_severity;
	assert (status_write_error		= '0')			report "fifo buggy !?!" severity bug_severity;

	-----------------------------------------------------------------------------
	-- Test read back
	-----------------------------------------------------------------------------
	read <= '1';
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	read <= '0';

	assert (free					= g_depth)		report "fifo buggy !?!" severity bug_severity;
	assert (used					= 0)			report "fifo buggy !?!" severity bug_severity;
	assert (status_empty			= '1')			report "fifo buggy !?!" severity bug_severity;
	assert (status_full				= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_read_error		= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_write_error		= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (read_data				= x"11")		report "fifo buggy !?!" severity bug_severity;

	-----------------------------------------------------------------------------
	-- Test fifo full
	-----------------------------------------------------------------------------
	write <= '1';
	for i in 0 to g_depth-1 loop
		write_data <= std_ulogic_vector(to_unsigned(i, 8));
		wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
		assert (free					= g_depth-i-1)	report "fifo buggy !?!" severity bug_severity;
		assert (used					= i+1)			report "fifo buggy !?!" severity bug_severity;
		assert (status_empty			= '0')			report "fifo buggy !?!" severity bug_severity;
		assert (status_read_error		= '0')			report "fifo buggy !?!" severity bug_severity;
		assert (status_write_error		= '0')			report "fifo buggy !?!" severity bug_severity;
		if i /= g_depth-1 then
			assert (status_full			= '0')			report "fifo buggy !?!" severity bug_severity;
		else
			assert (status_full			= '1')			report "fifo buggy !?!" severity bug_severity;
		end if;
	end loop;
	write <= '0';
	write_data <= x"00";

	-----------------------------------------------------------------------------
	-- Test write when full twice -> write error
	-----------------------------------------------------------------------------
	assert false									report "PIM_VHDL_WARNING_EXPECTED: Testing write when full, status_write_error expected" severity note;

	write <= '1';
	write_data <= x"22";
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	write_data <= x"00";
	write <= '0';

	assert (free					= 0)			report "fifo buggy !?!" severity bug_severity;
	assert (used					= g_depth)		report "fifo buggy !?!" severity bug_severity;
	assert (status_empty			= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_full				= '1')			report "fifo buggy !?!" severity bug_severity;
	assert (status_read_error		= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_write_error		= '1')			report "fifo buggy !?!" severity bug_severity;

	assert false									report "PIM_VHDL_WARNING_EXPECTED: Testing write when full:status_write_error expected" severity note;

	write <= '1';
	write_data <= x"22";
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	write_data <= x"00";
	write <= '0';

	assert (free					= 0)			report "fifo buggy !?!" severity bug_severity;
	assert (used					= g_depth)		report "fifo buggy !?!" severity bug_severity;
	assert (status_empty			= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_full				= '1')			report "fifo buggy !?!" severity bug_severity;
	assert (status_read_error		= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_write_error		= '1')			report "fifo buggy !?!" severity bug_severity;

	-----------------------------------------------------------------------------
	-- Test a simultaneous read/write while full, should work
	-----------------------------------------------------------------------------
	write <= '1';
	read <= '1';
	write_data <= std_ulogic_vector(to_unsigned(g_depth, 8));
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	write_data <= x"00";
	write <= '0';
	read <= '0';

	assert (free					= 0)			report "fifo buggy !?!" severity bug_severity;
	assert (used					= g_depth)		report "fifo buggy !?!" severity bug_severity;
	assert (status_empty			= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_full				= '1')			report "fifo buggy !?!" severity bug_severity;
	assert (status_read_error		= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_write_error		= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (read_data				= x"00")		report "fifo buggy !?!" severity bug_severity;

	-----------------------------------------------------------------------------
	-- Test write when full twice -> write error
	-----------------------------------------------------------------------------
	assert false									report "PIM_VHDL_WARNING_EXPECTED: Testing write when full:status_write_error expected" severity note;

	write <= '1';
	write_data <= x"22";
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	write_data <= x"00";
	write <= '0';

	assert (free					= 0)			report "fifo buggy !?!" severity bug_severity;
	assert (used					= g_depth)		report "fifo buggy !?!" severity bug_severity;
	assert (status_empty			= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_full				= '1')			report "fifo buggy !?!" severity bug_severity;
	assert (status_read_error		= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_write_error		= '1')			report "fifo buggy !?!" severity bug_severity;

	assert false									report "PIM_VHDL_WARNING_EXPECTED: Testing write when full:status_write_error expected" severity note;

	write <= '1';
	write_data <= x"22";
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	write_data <= x"00";
	write <= '0';

	assert (free					= 0)			report "fifo buggy !?!" severity bug_severity;
	assert (used					= g_depth)		report "fifo buggy !?!" severity bug_severity;
	assert (status_empty			= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_full				= '1')			report "fifo buggy !?!" severity bug_severity;
	assert (status_read_error		= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_write_error		= '1')			report "fifo buggy !?!" severity bug_severity;

	-----------------------------------------------------------------------------
	-- Test read back -> data should be ok
	-----------------------------------------------------------------------------

	read <= '1';

	for i in 0 to g_depth-1 loop
		wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
		assert read_data = std_ulogic_vector(to_unsigned(i+1, 8)) report "fifo buggy !?!" severity bug_severity;
		assert (free					= i+1)			report "fifo buggy !?!" severity bug_severity;
		assert (used					= g_depth-1-i)	report "fifo buggy !?!" severity bug_severity;
		assert (status_full				= '0')			report "fifo buggy !?!" severity bug_severity;
		assert (status_read_error		= '0')			report "fifo buggy !?!" severity bug_severity;
		assert (status_write_error		= '0')			report "fifo buggy !?!" severity bug_severity;
		if i /= g_depth-1 then
			assert (status_empty			= '0')		report "fifo buggy !?!" severity bug_severity;
		else
			assert (status_empty			= '1')		report "fifo buggy !?!" severity bug_severity;
		end if;
	end loop;

	-----------------------------------------------------------------------------
	-- Read twice while empty -> must fail twice
	-----------------------------------------------------------------------------
	assert false									report "PIM_VHDL_WARNING_EXPECTED: Testing read when empty:status_read_error expected" severity note;

	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	assert (free					= g_depth)		report "fifo buggy !?!" severity bug_severity;
	assert (used					= 0)			report "fifo buggy !?!" severity bug_severity;
	assert (status_full				= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_read_error		= '1')			report "fifo buggy !?!" severity bug_severity;
	assert (status_write_error		= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_empty			= '1')			report "fifo buggy !?!" severity bug_severity;

	assert false									report "PIM_VHDL_WARNING_EXPECTED: Testing read when empty:status_read_error expected" severity note;

	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	assert (free					= g_depth)		report "fifo buggy !?!" severity bug_severity;
	assert (used					= 0)			report "fifo buggy !?!" severity bug_severity;
	assert (status_full				= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_read_error		= '1')			report "fifo buggy !?!" severity bug_severity;
	assert (status_write_error		= '0')			report "fifo buggy !?!" severity bug_severity;
	assert (status_empty			= '1')			report "fifo buggy !?!" severity bug_severity;

	read <= '0';

	-----------------------------------------------------------------------------
	-- End of test
	-----------------------------------------------------------------------------

	assert false report "PIM_VHDL_SIMULATION_DONE" severity note;

	wait;

	end process;

end bhv;
