-----------------------------------------------------------------------------
-- file			: top.vhd
--
-- brief		: Counter to ft245
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

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity top_mimas_ft245_counter is
generic
(
	g_nrdata_log2		: natural := 7
);
port
(
	adbus			: inout	std_logic_vector(7 downto 0);
	rxf_n			: in	std_ulogic;
	txe_n			: in	std_ulogic;
	rd_n			: out	std_ulogic;
	wr_n			: out	std_ulogic;
	clkout			: in	std_ulogic;
	oe_n			: out	std_ulogic;
	siwu			: out	std_ulogic;
	reset_n			: out	std_ulogic;
	suspend_n		: in	std_ulogic;

	led				: out	std_ulogic_vector(7 downto 0) := x"aa";

	reset			: in	std_ulogic
);
end entity;

architecture rtl of top_mimas_ft245_counter is
	alias  clock is clkout;

	signal status_full		: std_ulogic;
	signal status_empty		: std_ulogic;
	signal read_data		: std_ulogic_vector(7 downto 0);
	signal tx_data			: std_ulogic_vector(7 downto 0);
	signal read				: std_ulogic;
	signal write			: std_ulogic;
	signal read_valid		: std_ulogic;

	signal counter			: unsigned(7 downto 0) := (others => '0');
begin

i_ft_if : entity work.ft245_sync_if
port map
(
	adbus			=> adbus,
	rxf_n			=> rxf_n,
	txe_n			=> txe_n,
	rd_n			=> rd_n,
	wr_n			=> wr_n,
	clock			=> clock,
	oe_n			=> oe_n,
	siwu			=> siwu,
	reset_n			=> reset_n,
	suspend_n		=> suspend_n,

	reset			=> reset,

	out_data		=> read_data,
	out_valid		=> read_valid,
	out_full		=> '0',

	in_data			=> tx_data,
	in_read			=> read,
	in_empty		=> status_empty
);

i_packetizer : entity work.packetizer
generic map
(
	g_nrdata_log2		=> g_nrdata_log2,
	g_depth_in_log2		=> 3,
	g_depth_out_log2	=> 5
)
port map
(
	clock			=> clock,
	reset			=> reset,

	write_data		=> std_ulogic_vector(counter),
	write			=> write,
	status_empty	=> status_empty,
	read_data		=> tx_data,
	read			=> read,
	status_full		=> status_full
);

write <= not status_full;
process(reset, clock)
begin
	if reset = '1' then
		counter <= (others => '0');
	elsif rising_edge(clock) then
		if status_full = '0' then
			counter <= counter + 1;
		end if;
	end if;
end process;

led_out: process(reset, clock)
begin
	if reset = '1' then
		led <= x"aa";
	elsif rising_edge(clock) then
		if read_valid = '1' then
			led <= read_data;
		end if;
	end if;
end process;

end architecture;
