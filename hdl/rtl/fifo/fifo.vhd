-----------------------------------------------------------------------------
-- file			: fifo.vhd 
--
-- brief		: Synchronous fifo
-- author(s)	: marc at pignat dot org
-- license		: The MIT License (MIT) (http://opensource.org/licenses/MIT)
--				  Copyright (c) 2015 Marc Pignat
-----------------------------------------------------------------------------
-- Features		:	* Generic size
--					* Maps into block ram (at least using xst)
--					* free/used output counters
--
-- Limitations	:	* input and output MUST be the same width
-- 					* same input and output clocks
--
-----------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity fifo is
	generic
	(
		g_depth_log2 : natural := 1 -- Log2 of the depth
	);
	port
	(
		clock		: in std_ulogic;
		reset		: in std_ulogic;

		-- input
		sync_reset	: in std_ulogic;
		write		: in std_ulogic;
		write_data	: in std_ulogic_vector;

		-- outputs
		read		: in std_ulogic;
		read_data	: out std_ulogic_vector;

		--status
		status_full			: out std_ulogic;
		status_empty		: out std_ulogic;
		status_write_error	: out std_ulogic;
		status_read_error	: out std_ulogic;
		
		free 				: out std_ulogic_vector(g_depth_log2 downto 0);
		used 				: out std_ulogic_vector(g_depth_log2 downto 0)
	);

type mem_t is array ( (2 **g_depth_log2 ) - 1 downto 0) of std_ulogic_vector(write_data'range);
subtype mem_range_r is natural range (g_depth_log2 - 1) downto 0;
subtype ptr_range_r is natural range (g_depth_log2 - 0) downto 0;
end fifo;

architecture rtl of fifo is

	signal mem 				: mem_t := (others => (others => '0'));
                        	
	signal full				: std_ulogic;
	signal empty			: std_ulogic;
	signal write_error		: std_ulogic;
	signal read_error		: std_ulogic;
	signal read_ptr			: unsigned(ptr_range_r);
	signal read_ptr_next	: unsigned(ptr_range_r);
	signal write_ptr		: unsigned(ptr_range_r);
	signal write_ptr_next	: unsigned(ptr_range_r);
	
	signal used_int 		: unsigned(used'range);
begin

-----------------------------------------------------------------------------
-- Free / used
-----------------------------------------------------------------------------
fifo_count_proc: process(reset, clock)
begin
	if reset = '1' then
		used_int <= (others => '0');
	elsif rising_edge(clock) then
		if write = '1' and full = '0' then
			used_int <= used_int + 1;
		end if;
		if read = '1' and empty = '0' then
			used_int <= used_int - 1;
		end if;

		-- Simultaneous read/write -> no change
		-- ignore full, since it is valid
		if write = '1' and read = '1' and empty = '0' then
			used_int <= used_int;
		end if;

		if sync_reset = '1' then
			used_int <= (others => '0');
		end if;
	end if;
end process;

used <= std_ulogic_vector(used_int);
free <= std_ulogic_vector(to_unsigned(2**g_depth_log2, free'left + 1) - used_int);

-----------------------------------------------------------------------------
-- FIFO status export
-----------------------------------------------------------------------------
status_full			<= full;
status_empty		<= empty;
status_write_error	<= write_error;
status_read_error	<= read_error;

-----------------------------------------------------------------------------
-- FIFO status
-----------------------------------------------------------------------------

full	<= '1' when (write_ptr(write_ptr'left) /= read_ptr(read_ptr'left)) and ((write_ptr(mem_range_r) = read_ptr(mem_range_r))) else '0';
empty	<= '1' when (write_ptr = read_ptr) else '0';

write_ptr_next <= write_ptr + 1;
read_ptr_next <= read_ptr + 1;

fifo_ptr_proc: process(reset, clock)
begin
	if reset = '1' then
		write_ptr <= (others => '0');
		read_ptr <= (others => '0');
		write_error <= '0';
		read_error <= '0';	
	elsif rising_edge(clock) then
		write_error <= '0';
		read_error <= '0';	
		if write = '1' then
			if full = '0' or read = '1' then
				write_ptr <= write_ptr_next;
			else
				write_error <= '1';
			end if;
		end if;
		if read = '1' then
			if empty = '0' then
				read_ptr <= read_ptr_next;
			else
				read_error <= '1';
			end if;
		end if;

		if sync_reset = '1' then
			write_ptr <= (others => '0');
			read_ptr <= (others => '0');
		end if;
	end if;
end process;

fifo_out_proc : process(clock)
begin
	if rising_edge(clock) then
		read_data <= mem(to_integer(read_ptr(mem_range_r)));
		--pragma synthesis_off
		if read = '0' then
			read_data <= (others => 'U');
		end if;
		--pragma synthesis_on
	end if;
end process;

fifo_in_proc : process(clock)
begin
	if rising_edge(clock) then
		if write = '1' and full = '0' then
			mem(to_integer(write_ptr(mem_range_r))) <= write_data;
		end if;
	end if;
end process;

end architecture rtl;