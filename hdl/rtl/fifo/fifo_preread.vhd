-----------------------------------------------------------------------------
-- file			: fifo_preread.vhd
--
-- brief		: Synchronous fifo pre-reading one data
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

entity fifo_preread is
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
		status_read_error	: out std_ulogic := '0';

		free				: out std_ulogic_vector(g_depth_log2 downto 0);
		used				: out std_ulogic_vector(g_depth_log2 downto 0)
	);
end fifo_preread;

architecture rtl of fifo_preread is
	signal read_data_fifo	: std_ulogic_vector(read_data'range);
	signal read_data_int	: std_ulogic_vector(read_data'range) := (others => '0');
	signal read_fifo		: std_ulogic;
	signal read_fifo_old	: std_ulogic := '0';
	signal status_empty_fifo: std_ulogic;
	signal data_ready		: std_ulogic := '0';
begin

status_empty	<= not data_ready;
read_fifo		<= (read and not status_empty_fifo) or (not data_ready and not status_empty_fifo and not read_fifo_old);

read_data <= read_data_int when read_fifo_old = '0' else read_data_fifo;

data_out: process(reset, clock)
begin
	if reset = '1' then
		read_data_int	<= (others => '0');
		read_fifo_old	<= '0';
		data_ready		<= '0';
		status_read_error<= '0';

		--pragma synthesis_off
		read_data_int	<= (others => 'U');
		--pragma synthesis_on

	elsif rising_edge(clock) then
		read_fifo_old	<= read_fifo;
		if read_fifo_old = '1' then
			read_data_int	<= read_data_fifo;
			data_ready		<= '1';
		end if;

		if read = '1' and status_empty_fifo = '1' then
			data_ready		<= '0';
			--pragma synthesis_off
			read_data_int	<= (others => 'U');
			--pragma synthesis_on
		end if;

		status_read_error <= '0';
		if read = '1' and data_ready = '0' then
			status_read_error <= '1';

			--pragma synthesis_off
			assert (false) report "status_read_error" severity warning;
			--pragma synthesis_on
		end if;

		if reset_sync = '1' then
			read_data_int	<= (others => '0');
			read_fifo_old	<= '0';
			data_ready		<= '0';
			status_read_error<= '0';

			--pragma synthesis_off
			read_data_int	<= (others => 'U');
			--pragma synthesis_on
		end if;
	end if;
end process;

i_fifo: entity work.fifo
generic map
(
	g_depth_log2		=> g_depth_log2
)
port map
(
	clock				=> clock,
	reset				=> reset,
	reset_sync			=> reset_sync,

	-- input
	write				=> write,
	write_data			=> write_data,

	-- outputs
	read				=> read_fifo,
	read_data			=> read_data_fifo,

	--status
	status_full			=> status_full,
	status_empty		=> status_empty_fifo,
	status_write_error	=> status_write_error,
	status_read_error	=> open,

	free				=> free,
	used				=> used
);
end architecture rtl;
