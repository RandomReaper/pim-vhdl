-----------------------------------------------------------------------------
-- file			: tb.vhd 
--
-- brief		: Test bench
-- author(s)	: marc at pignat dot org
-- license		: The MIT License (MIT) (http://opensource.org/licenses/MIT)
--				  Copyright (c) 2015 Marc Pignat
-----------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity tb is
end tb;

architecture bhv of tb is
	constant g_depth_log2 : integer := 2;
	constant g_depth : integer := 2**g_depth_log2;
	constant half_period : time := 0.5 ns;

	signal reset 				: std_ulogic;
	signal clock 				: std_ulogic;
	signal sync_reset			: std_ulogic;
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
			sync_reset			=> sync_reset,
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
	sync_reset		<= '0';
	read			<= '0';
	write			<= '0';
	write_data		<= x"00";
	clock <= '0';
	
	wait for half_period; wait for half_period;
	
	reset			<= '0';
	-----------------------------------------------------------------------------
	-- Verify all outputs after reset
	-----------------------------------------------------------------------------
	assert (free					= g_depth)		report "fifo buggy !?!" severity failure;
	assert (used					= 0)			report "fifo buggy !?!" severity failure;
	assert (status_empty			= '1')          report "fifo buggy !?!" severity failure;
	assert (status_full				= '0')          report "fifo buggy !?!" severity failure;
	assert (status_read_error		= '0')          report "fifo buggy !?!" severity failure;
	assert (status_write_error		= '0')          report "fifo buggy !?!" severity failure;
		
	-----------------------------------------------------------------------------
	-- Test a read when empty
	-----------------------------------------------------------------------------
	assert false									report "Testing read when empty, warning:status_read_error expected" severity note;

	read <= '1';
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	read <= '0';
	
	assert (free					= g_depth)		report "fifo buggy !?!" severity failure;
	assert (used					= 0)			report "fifo buggy !?!" severity failure;
	assert (status_empty			= '1')          report "fifo buggy !?!" severity failure;
	assert (status_full				= '0')          report "fifo buggy !?!" severity failure;
	assert (status_read_error		= '1')          report "fifo buggy !?!" severity failure;
	assert (status_write_error		= '0')          report "fifo buggy !?!" severity failure;

	-----------------------------------------------------------------------------
	-- Test a write
	-----------------------------------------------------------------------------

	write <= '1';
	write_data <= x"55";
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	write_data <= x"00";
	write <= '0';

	assert (free					= g_depth-1)	report "fifo buggy !?!" severity failure;
	assert (used					= 1)			report "fifo buggy !?!" severity failure;
	assert (status_empty			= '0')          report "fifo buggy !?!" severity failure;
	assert (status_full				= '0')          report "fifo buggy !?!" severity failure;
	assert (status_read_error		= '0')          report "fifo buggy !?!" severity failure;
	assert (status_write_error		= '0')          report "fifo buggy !?!" severity failure;

	-----------------------------------------------------------------------------
	-- Test a simultaneous read/write while empty, should work
	-----------------------------------------------------------------------------
	write <= '1';
	read <= '1';
	write_data <= x"aa";
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	write_data <= x"00";
	write <= '0';
	read <= '0';

	assert (free					= g_depth-1)	report "fifo buggy !?!" severity failure;
	assert (used					= 1)			report "fifo buggy !?!" severity failure;
	assert (status_empty			= '0')          report "fifo buggy !?!" severity failure;
	assert (status_full				= '0')          report "fifo buggy !?!" severity failure;
	assert (status_read_error		= '0')          report "fifo buggy !?!" severity failure;
	assert (status_write_error		= '0')          report "fifo buggy !?!" severity failure;
	assert (read_data				= x"55")		report "fifo buggy !?!" severity failure;

	-----------------------------------------------------------------------------
	-- Test read back
	-----------------------------------------------------------------------------
	read <= '1';
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	read <= '0';

	assert (free					= g_depth)		report "fifo buggy !?!" severity failure;
	assert (used					= 0)			report "fifo buggy !?!" severity failure;
	assert (status_empty			= '1')          report "fifo buggy !?!" severity failure;
	assert (status_full				= '0')          report "fifo buggy !?!" severity failure;
	assert (status_read_error		= '0')          report "fifo buggy !?!" severity failure;
	assert (status_write_error		= '0')          report "fifo buggy !?!" severity failure;
	assert (read_data				= x"aa")		report "fifo buggy !?!" severity failure;

	-----------------------------------------------------------------------------
	-- Test synchronous reset
	-----------------------------------------------------------------------------
	write <= '1';
	write_data <= x"55";
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	write_data <= x"00";
	write <= '0';
	sync_reset		<= '1';

	-- should not reset before clock !
	assert (free					= g_depth-1)	report "fifo buggy !?!" severity failure;
	assert (used					= 1)			report "fifo buggy !?!" severity failure;
	assert (status_empty			= '0')          report "fifo buggy !?!" severity failure;
	assert (status_full				= '0')          report "fifo buggy !?!" severity failure;
	assert (status_read_error		= '0')          report "fifo buggy !?!" severity failure;
	assert (status_write_error		= '0')          report "fifo buggy !?!" severity failure;
	
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	sync_reset		<= '0';
	-- Now should be reset
	assert (free					= g_depth)		report "fifo buggy !?!" severity failure;
	assert (used					= 0)			report "fifo buggy !?!" severity failure;
	assert (status_empty			= '1')          report "fifo buggy !?!" severity failure;
	assert (status_full				= '0')          report "fifo buggy !?!" severity failure;
	assert (status_read_error		= '0')          report "fifo buggy !?!" severity failure;
	assert (status_write_error		= '0')          report "fifo buggy !?!" severity failure;	


	-----------------------------------------------------------------------------
	-- Test a simultaneous read/write while empty, (read should fail)
	-----------------------------------------------------------------------------
	assert false									report "Testing read/write while empty, warning:status_read_error expected" severity note;

	write <= '1';
	read <= '1';
	write_data <= x"11";
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	write_data <= x"00";
	write <= '0';
	read <= '0';

	assert (free					= g_depth-1)	report "fifo buggy !?!" severity failure;
	assert (used					= 1)			report "fifo buggy !?!" severity failure;
	assert (status_empty			= '0')          report "fifo buggy !?!" severity failure;
	assert (status_full				= '0')          report "fifo buggy !?!" severity failure;
	assert (status_read_error		= '1')          report "fifo buggy !?!" severity failure;
	assert (status_write_error		= '0')          report "fifo buggy !?!" severity failure;
	
	-----------------------------------------------------------------------------
	-- Test read back
	-----------------------------------------------------------------------------
	read <= '1';
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	read <= '0';

	assert (free					= g_depth)		report "fifo buggy !?!" severity failure;
	assert (used					= 0)			report "fifo buggy !?!" severity failure;
	assert (status_empty			= '1')          report "fifo buggy !?!" severity failure;
	assert (status_full				= '0')          report "fifo buggy !?!" severity failure;
	assert (status_read_error		= '0')          report "fifo buggy !?!" severity failure;
	assert (status_write_error		= '0')          report "fifo buggy !?!" severity failure;
	assert (read_data				= x"11")		report "fifo buggy !?!" severity failure;	
	
	-----------------------------------------------------------------------------
	-- Test fifo full
	-----------------------------------------------------------------------------
	write <= '1';
	for i in 0 to g_depth-1 loop
		write_data <= std_ulogic_vector(to_unsigned(i, 8));
		wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	end loop;
	write <= '0';
	write_data <= x"00";

	assert (free					= 0)			report "fifo buggy !?!" severity failure;
	assert (used					= g_depth)		report "fifo buggy !?!" severity failure;
	assert (status_empty			= '0')          report "fifo buggy !?!" severity failure;
	assert (status_full				= '1')          report "fifo buggy !?!" severity failure;
	assert (status_read_error		= '0')          report "fifo buggy !?!" severity failure;
	assert (status_write_error		= '0')          report "fifo buggy !?!" severity failure;	
	
	-----------------------------------------------------------------------------
	-- Test a simultaneous read/write while full, should work
	-----------------------------------------------------------------------------
	write <= '1';
	read <= '1';
	write_data <= x"11";
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	write_data <= x"00";
	write <= '0';
	read <= '0';

	assert (free					= 0)			report "fifo buggy !?!" severity failure;
	assert (used					= g_depth)		report "fifo buggy !?!" severity failure;
	assert (status_empty			= '0')          report "fifo buggy !?!" severity failure;
	assert (status_full				= '1')          report "fifo buggy !?!" severity failure;
	assert (status_read_error		= '0')          report "fifo buggy !?!" severity failure;
	assert (status_write_error		= '0')          report "fifo buggy !?!" severity failure;	
	assert (read_data				= x"00")		report "fifo buggy !?!" severity failure;	

	-----------------------------------------------------------------------------
	-- Test write when full -> write error
	-----------------------------------------------------------------------------
	assert false									report "Testing write when full, warning:status_write_error expected" severity note;

	write <= '1';
	write_data <= x"22";
	wait for half_period; clock <= '1'; wait for half_period; clock <= '0';
	write_data <= x"00";
	write <= '0';

	assert (free					= 0)			report "fifo buggy !?!" severity failure;
	assert (used					= g_depth)		report "fifo buggy !?!" severity failure;
	assert (status_empty			= '0')          report "fifo buggy !?!" severity failure;
	assert (status_full				= '1')          report "fifo buggy !?!" severity failure;
	assert (status_read_error		= '0')          report "fifo buggy !?!" severity failure;
	assert (status_write_error		= '1')          report "fifo buggy !?!" severity failure;	

	-----------------------------------------------------------------------------
	-- End of test
	-----------------------------------------------------------------------------

	wait;
	
	end process;

end bhv;
