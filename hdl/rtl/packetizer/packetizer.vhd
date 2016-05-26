-----------------------------------------------------------------------------
-- file			: packetizer.vhd
--
-- brief		: packetizer
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

entity packetizer is
generic
(
	g_nrdata_log2		: natural := 5;
	g_depth_in_log2		: natural := 2;
	g_depth_out_log2	: natural := 5
);
port
(
	clock			: in	std_ulogic;
	reset			: in	std_ulogic;

	write			: in	std_ulogic;
	write_data		: in	std_ulogic_vector(7 downto 0);

	read_data		: out	std_ulogic_vector(7 downto 0);
	read			: in	std_ulogic;

	status_empty	: out	std_ulogic;
	status_full		: out	std_ulogic
);
end packetizer;

architecture rtl of packetizer is
	signal tx_write		: std_ulogic;
	signal tx_data		: std_ulogic_vector(read_data'range);
	signal tx_full		: std_ulogic;
	signal rx_read		: std_ulogic;
	signal rx_empty		: std_ulogic;
	signal rx_data		: std_ulogic_vector(write_data'range);
	signal rx_full		: std_ulogic;

	signal packet_count : unsigned(7 downto 0) := (others => '0');
	signal in_count		: unsigned(g_nrdata_log2 downto 0) := (others => '0');

	type state_e is
	(
		STATE_RESET,
		STATE_IDLE,
		STATE_HEADER,
		STATE_DATA
	);

	type state_t is
	record
		name	: state_e;
		counter	: unsigned(7 downto 0);
	end record;

	signal state		: state_t :=
		(name => STATE_RESET, counter => (others => '0'));
	signal next_state	: state_t;

	signal header		: std_ulogic_vector(read_data'range);
begin

state_machine: process(reset, clock)
begin
	if reset = '1' then
		state.name			<= STATE_RESET;
		state.counter		<= (others => '0');
	elsif rising_edge(clock) then
		state		<= next_state;
	end if;
end process;

state_machine_next: process(state, rx_empty, tx_full, rx_read)
begin
	next_state <= state;

	case state.name is
		when STATE_RESET =>
			next_state.name <= STATE_IDLE;

		when STATE_IDLE =>
			if rx_empty = '0' then
				next_state.name <= STATE_HEADER;
				next_state.counter <= (others => '0');
			end if;

		when STATE_HEADER =>
			if tx_full = '0' then
				next_state.counter <= state.counter+1;
			end if;
			if tx_full = '0' and state.counter = 16-1 then
				next_state.name <= STATE_DATA;
				next_state.counter <= (others => '0');
			end if;

		when STATE_DATA =>
			if rx_read = '1' then
				next_state.counter <= state.counter+1;
			end if;

			if rx_read = '1' and state.counter = (2**g_nrdata_log2) - 1 then
				next_state.name <= STATE_IDLE;
				next_state.counter <= (others => '0');
			end if;
	end case;
end process;

with state.name select rx_read <=
	(not rx_empty) and (not tx_full)	when STATE_DATA,
	'0'									when others;

with state.name select tx_data <=
	header			when STATE_HEADER,
	rx_data			when STATE_DATA,
	(others => '0')	when others;

with state.name select tx_write <=
	not tx_full	when STATE_HEADER,
	rx_read when STATE_DATA,
	'0'			when others;

with to_integer(state.counter) select header <=
	-- ASCII "yoho"
	x"79"								when 0,
	x"6f"								when 1,
	x"68"								when 2,
	x"6f"								when 3,

	-- Version, type data, packet count, 0
	x"00"								when 4,
	x"00"								when 5,
	std_ulogic_vector(packet_count)		when 6,
	x"00"								when 7,

	-- 16 bit packet size, 0,0
	std_ulogic_vector(to_unsigned((2**g_nrdata_log2) /	(2**8),8))		when 8,
	std_ulogic_vector(to_unsigned((2**g_nrdata_log2) mod(2**8),8))		when 9,
	x"00"			when 10,
	x"00"			when 11,

	-- junk (0x89abcdef)
	x"89"			when 12,
	x"ab"			when 13,
	x"cd"			when 14,
	x"ef"			when 15,

	(others => '0')	when others;

status_full <= rx_full;

packet_count_gen: process(reset, clock)
begin
	if reset = '1' then
		packet_count <= (others => '0');
	elsif rising_edge(clock) then
		if state.name = STATE_IDLE and next_state.name = STATE_HEADER then
			packet_count <= packet_count + 1;
		end if;
	end if;
end process;

in_count_gen: process(reset, clock)
begin
	if reset = '1' then
		in_count <= (others => '0');
	elsif rising_edge(clock) then
		if rx_read = '1' then
			in_count <= in_count + 1;
		end if;
	end if;
end process;

i_fifo_in: entity work.fifo_preread
generic map
(
	g_depth_log2	=> g_depth_in_log2
)
port map
(
	clock		=> clock,
	reset		=> reset,
	reset_sync	=> '0',
	write		=> write,
	write_data	=> write_data,

	read		=> rx_read,
	read_data	=> rx_data,
	status_empty=> rx_empty,
	status_full	=> rx_full
);

i_fifo_out: entity work.fifo
generic map
(
	g_depth_log2	=> g_depth_out_log2
)
port map
(
	clock		=> clock,
	reset		=> reset,
	reset_sync	=> '0',
	write		=> tx_write,
	write_data	=> tx_data,

	read		=> read,
	read_data	=> read_data,
	status_empty=> status_empty,
	status_full	=> tx_full
);

end rtl;
