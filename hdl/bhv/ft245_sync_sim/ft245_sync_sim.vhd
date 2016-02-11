-----------------------------------------------------------------------------
-- file		: clock.vhd 
--
-- brief		: Simulate a FT2232H in FT245 Synchronous fifo mode
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

entity ft245_sync_sim is
	port
	(
		adbus		: inout	std_logic_vector(7 downto 0);
		rxf_n		: out	std_ulogic;
		txe_n		: out	std_ulogic;
		rd_n		: in	std_ulogic;
		wr_n		: in	std_ulogic;
		clock		: in	std_ulogic;
		oe_n		: in	std_ulogic;
		siwu		: in	std_ulogic;
		reset_n		: in	std_ulogic;
		suspend_n	: out	std_ulogic;
		
		d_data_out	: out	std_ulogic_vector(7 downto 0);
		d_data_out_valid : out std_ulogic;
		d_data_in	: in	std_ulogic_vector(7 downto 0);
		d_data_write: in	std_ulogic;
		d_data_full	: out	std_ulogic
	);
end ft245_sync_sim ;

architecture bhv of ft245_sync_sim is
	signal reset		: std_ulogic;
	signal oe			: std_ulogic;
	signal rd			: std_ulogic;
	signal data_in		: std_ulogic_vector(adbus'range);
	signal data_in_pre	: std_ulogic_vector(adbus'range);
	signal d_data_out_in	: std_ulogic_vector(adbus'range);
	signal tx_full		: std_ulogic;
	signal status_empty	: std_ulogic;
	signal status_full	: std_ulogic;
	signal rd_empty		: std_ulogic;
	signal wr			: std_ulogic;
	signal tx_enable	: std_ulogic;
	signal tx_enable_old: std_ulogic;
	signal tx_fifo_empty: std_ulogic;
	signal txe			: std_ulogic;
	signal tx			: std_ulogic;
begin

oe			<= not oe_n;
wr			<= not wr_n and txe and not tx_full;
rxf_n		<= status_empty;
txe_n		<= not txe or tx_full;
suspend_n	<= '0';
d_data_full <= status_full;
tx			<= tx_enable and not tx_fifo_empty;
tx_counter_gen: process(reset, clock)
begin
	if reset = '1' then
		tx_enable	<= '0';
		txe			<= '0';
		tx_enable_old<= '0';
	elsif rising_edge(clock) then
		tx_enable_old<= tx;
		if tx_full = '1' then
			tx_enable <= '1';
			txe		  <= '0';
		end if;
		if tx_fifo_empty = '1' then
			tx_enable <= '0';
			txe		  <= '1';
		end if;
	end if;
end process;

adbus <= std_logic_vector(data_in) when oe = '1' else (others => 'Z');

i_from_host_fifo: entity work.fifo_preread
generic map
(
	g_depth_log2 => 4
)
port map
(
	clock		=> clock,
	reset		=> reset,

	-- input
	sync_reset	=> '0',
	write		=> d_data_write,
	write_data	=> d_data_in,

	-- outputs
	read		=> rd,
	read_data	=> data_in,

	--status
	status_full	=> status_full,
	status_empty	=> status_empty
);

data_out_gen: process(reset, clock)
begin
	if reset = '1' then
		d_data_out	<= (others => '-');
		d_data_out_valid <= '0';
	elsif rising_edge(clock) then
		d_data_out	<= (others => '-');
		d_data_out_valid <= '0';
		if tx_enable_old = '1' then
			d_data_out <= d_data_out_in;
			d_data_out_valid <= '1';
		end if;
	end if;
end process;

i_to_host_fifo: entity work.fifo
generic map
(
	g_depth_log2 => 4
)
port map
(
	clock		=> clock,
	reset		=> reset,

	-- input
	sync_reset	=> '0',
	write		=> wr,
	write_data	=> std_ulogic_vector(adbus),

	-- outputs
	read		=> tx,
	read_data	=> d_data_out_in,

	--status
	status_full	=> tx_full,
	status_empty	=> tx_fifo_empty
);

rd <= not rd_n and not status_empty;

i_reset : entity work.reset
port map
(
	reset	=> reset,
	clock	=> clock
);

end architecture bhv;
