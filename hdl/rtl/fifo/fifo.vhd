-----------------------------------------------------------------------------
-- file			: fifo.vhd
--
-- brief		: Synchronous fifo
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
	clock				: in std_ulogic;
	reset				: in std_ulogic;
	reset_sync			: in std_ulogic;

	-- input
	write				: in std_ulogic;
	write_data			: in std_ulogic_vector;

	-- outputs
	read				: in std_ulogic;
	read_data			: out std_ulogic_vector;

	--status
	status_full			: out std_ulogic;
	status_empty		: out std_ulogic;
	status_write_error	: out std_ulogic;
	status_read_error	: out std_ulogic;

	free				: out std_ulogic_vector(g_depth_log2 downto 0);
	used				: out std_ulogic_vector(g_depth_log2 downto 0)
);
end fifo;

architecture rtl of fifo is
	type mem_t is array ( (2 **g_depth_log2 ) - 1 downto 0) of std_ulogic_vector(write_data'range);
	subtype mem_range_r is natural range (g_depth_log2 - 1) downto 0;
	subtype ptr_range_r is natural range (g_depth_log2 - 0) downto 0;

	signal mem				: mem_t := (others => (others => '0'));

	signal full				: std_ulogic := '0';
	signal empty			: std_ulogic := '1';
	signal write_error		: std_ulogic := '0';
	signal read_error		: std_ulogic := '0';
	signal read_ptr			: unsigned(ptr_range_r) := (others => '0');
	signal read_ptr_next	: unsigned(ptr_range_r);
	signal write_ptr		: unsigned(ptr_range_r) := (others => '0');
	signal write_ptr_next	: unsigned(ptr_range_r);

	signal full_async		: std_ulogic;
	signal empty_async		: std_ulogic;

	signal used_int			: unsigned(used'range) := (others => '0');
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

		if reset_sync = '1' then
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

full_async	<= '1' when (write_ptr(write_ptr'left) /= read_ptr(read_ptr'left)) and ((write_ptr(mem_range_r) = read_ptr(mem_range_r))) else '0';
empty_async	<= '1' when (write_ptr = read_ptr) else '0';

write_ptr_next <= write_ptr + 1;
read_ptr_next <= read_ptr + 1;

fifo_ptr_proc: process(reset, clock)
begin
	if reset = '1' then
		write_ptr <= (others => '0');
		read_ptr <= (others => '0');
		write_error <= '0';
		read_error <= '0';
		full <= '0';
		empty <= '1';
	elsif rising_edge(clock) then
		write_error <= '0';
		read_error <= '0';

		if write = '1' then
			if full_async = '0' or read = '1' then
				write_ptr <= write_ptr_next;
			else
				write_error <= '1';

			--pragma synthesis_off
			assert (false) report "status_write_error" severity warning;
			--pragma synthesis_on

			end if;
		end if;
		if read = '1' then
			if empty_async = '0' then
				read_ptr <= read_ptr_next;
			else
				read_error <= '1';

			--pragma synthesis_off
			assert (false) report "status_read_error" severity warning;
			--pragma synthesis_on

			end if;
		end if;

		if read = '1' and write = '0' then
			full <= '0';
			if empty_async = '1' or (write_ptr = read_ptr_next) then
				empty <= '1';
			end if;
		end if;

		if read = '0' and write = '1' then
			empty <= '0';
			if full_async = '1' or ((write_ptr_next(write_ptr'left) /= read_ptr(read_ptr'left)) and ((write_ptr_next(mem_range_r) = read_ptr(mem_range_r)))) then
				full <= '1';
			end if;
		end if;

		if read = '1' and write = '1' then
			empty <= '0';
		end if;

		if reset_sync = '1' then
			write_ptr <= (others => '0');
			read_ptr <= (others => '0');
			write_error <= '0';
			read_error <= '0';
			full <= '0';
			empty <= '1';
		end if;

	end if;
end process;

fifo_out_proc : process(clock)
begin
	if rising_edge(clock) then
		read_data <= mem(to_integer(read_ptr(mem_range_r)));

		--pragma synthesis_off
		if read = '0' then
			read_data(read_data'range) <= (others => 'U');
		end if;
		--pragma synthesis_on

	end if;
end process;

fifo_in_proc : process(clock)
begin

	--pragma synthesis_off
	if reset = '1' then
		mem <= (others => (others =>'U'));
	end if;
	--pragma synthesis_on

	if rising_edge(clock) then
		--pragma synthesis_off
		if read = '1' and empty_async = '0' then
			mem(to_integer(read_ptr(mem_range_r))) <= (others => 'U');
		end if;
		--pragma synthesis_on

		if write = '1' and (full_async = '0' or read = '1') then
			mem(to_integer(write_ptr(mem_range_r))) <= write_data;
		end if;

		if reset_sync = '1' then
			--pragma synthesis_off
			mem <= (others => (others =>'U'));
			--pragma synthesis_on
		end if;
	end if;
end process;

end architecture rtl;