-----------------------------------------------------------------------------
-- file			: depacketizer.vhd
--
-- brief		: depacketizer
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

entity depacketizer is
generic
(
	g_nrdata_log2		: natural := 5
);
port
(
	clock			: in	std_ulogic;
	reset			: in	std_ulogic;

	in_data			: in	std_ulogic_vector(7 downto 0);
	in_valid		: in	std_ulogic;

	out_data		: out	std_ulogic_vector(7 downto 0);
	out_valid		: out	std_ulogic;

	header_valid	: out	std_ulogic
);
end depacketizer;

architecture rtl of depacketizer is
	type buf_t is array(3 downto 0) of std_ulogic_vector(in_data'range);
	signal buf					: buf_t;

	type state_t is
	(
		STATE_RESET,
		STATE_IDLE,
		STATE_HEADER,
		STATE_DATA
	);

	signal header_counter		: unsigned(5 downto 0);
	signal data_counter			: unsigned(g_nrdata_log2 downto 0);

	signal state				: state_t;
	signal next_state			: state_t;

	signal out_valid_int		: std_ulogic;
	signal out_data_int			: std_ulogic_vector(out_data'range);
begin

buffer_proc: process(reset, clock)
begin
	if reset = '1' then
		buf <= (others =>(others => '0'));
	elsif rising_edge(clock) then
		if in_valid = '1' and state = STATE_IDLE then
			for i in buf'left downto 1 loop
				buf(i) <= buf(i-1);
			end loop;
			buf(0) <= in_data;
		end if;

		if state /= STATE_IDLE then
			buf <= (others =>(others => '0'));
		end if;
	end if;
end process;

state_proc: process(reset, clock)
begin
	if reset = '1' then
		state <= STATE_RESET;
	elsif rising_edge(clock) then
		state <= next_state;
	end if;
end process;

counter_proc:
process(reset, clock)
begin
	if reset = '1' then
		header_counter <= (others => '0');
	elsif rising_edge(clock) then
		if state = STATE_HEADER then
			if in_valid = '1' then
				header_counter <= header_counter + 1;
			end if;
		else
			header_counter <= to_unsigned(4, header_counter'length);

			if in_valid = '1' then
				header_counter <= to_unsigned(5, header_counter'length);
			end if;
		end if;

		if state = STATE_DATA then
			if in_valid = '1' then
			data_counter <= data_counter + 1;
			end if;
		else
			data_counter <= (others => '0');
		end if;
	end if;
end process;

next_state_proc: process(state, buf, header_counter, data_counter, in_valid)
begin
	next_state <= state;

	case state is
		when STATE_RESET =>
			next_state <= STATE_IDLE;

		when STATE_IDLE =>
			if buf(3) = x"79" and buf(2) = x"6f" and buf(1) = x"68" and buf(0) = x"6f" then
				next_state <= STATE_HEADER;
			end if;

		when STATE_HEADER =>
			if in_valid = '1' and header_counter >= 15 then
				next_state <= STATE_DATA;
			end if;

		when STATE_DATA =>
			if in_valid = '1' and data_counter = 2 ** g_nrdata_log2 - 1 then
				next_state <= STATE_IDLE;
			end if;
	end case;
end process;

out_valid <= out_valid_int;
with state select out_valid_int <=
	in_valid	when STATE_DATA,
	'0'			when others;

out_data <= out_data_int;

out_data_proc: process(in_data, out_valid_int)
begin
	out_data_int <= in_data;

	--pragma synthesis_off
	if out_valid_int /= '1' then
		out_data_int <= (others => '-');
	end if;
	--pragma synthesis_on
end process;
end rtl;
