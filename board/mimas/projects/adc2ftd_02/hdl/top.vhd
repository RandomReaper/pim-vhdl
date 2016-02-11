-----------------------------------------------------------------------------
-- file			: top.vhd 
--
-- brief		: adc2ftd_02 top
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
	
entity top is
generic
(
	g_parallel : natural := 4
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
	
	led				: out	std_ulogic_vector(7 downto 0);
	
	reset			: in	std_ulogic;
	-- ADCs
	sclk			: out	std_ulogic;
	n_cs			: out	std_ulogic;
	sdata			: in	std_ulogic_vector(g_parallel-1 downto 0)
);
begin end;

architecture rtl of top is
	alias  clock			is clkout;
	
	signal read_data		: std_ulogic_vector(adbus'range);
	signal read_valid		: std_ulogic;
	signal ftd_data			: std_ulogic_vector(adbus'range);
	signal ftd_read			: std_ulogic;
	signal ftd_empty		: std_ulogic;
	
	signal adc_data48		: std_ulogic_vector(g_parallel*12-1 downto 0);
	signal adc_data64		: std_ulogic_vector(g_parallel*16-1 downto 0);
	signal adc_data_valid	: std_ulogic;
	signal adc_data8		: std_ulogic_vector(adbus'range);
	signal adc_data8_valid	: std_ulogic;
begin

i_ft245: entity work.ft245_sync_if
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
	
	read_data		=> read_data,
	read_valid		=> read_valid,
	
	write_data		=> ftd_data,
	write_read		=> ftd_read,
	write_empty		=> ftd_empty
);

i_ad7476_p_if: entity work.ad7476_parallel_if
generic map
(
	g_prescaler	=> 1,
	g_parallel	=> g_parallel
)
port map
(
	reset	=> reset,
	clock	=> clock,
	
	sclk	=> sclk,
	n_cs	=> n_cs,
	sdata	=> sdata,
	
	data		=> adc_data48,
	data_valid	=> adc_data_valid
);

process(adc_data48)
begin
	for i in 0 to g_parallel-1 loop
		adc_data64((16*(i+1))-1 downto 16*i) <= adc_data48((12*(i+1))-1 downto 12*i) & std_ulogic_vector(to_unsigned(i+1, 4));
	end loop;
end process;

i_wc: entity work.width_changer
port map
(
	clock			=> clock,
	reset			=> reset,
	
	in_data			=> adc_data64,
	in_data_valid	=> adc_data_valid,
	in_data_ready	=> open,
	out_data		=> adc_data8,
	out_data_valid	=> adc_data8_valid
);

i_packetizer: entity work.packetizer
generic map
(
	g_nrdata_log2		=> 5,
	g_depth_in_log2		=> 3,
	g_depth_out_log2	=> 5
)
port map
(
	reset			=> reset,
	clock			=> clock,
	
	write_data		=> adc_data8,
	write			=> adc_data8_valid,
	
	read_data		=> ftd_data,
	status_empty	=> ftd_empty,
	read			=> ftd_read
);

led_proc: process(reset, clock)
begin
	if reset = '1' then
		led <= x"55";
	elsif rising_edge(clock) then
		if read_valid = '1' then
			led <= read_data;
		end if;
	end if;
end process;

end rtl;