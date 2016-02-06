-----------------------------------------------------------------------------
-- file			: top.vhd 
--
-- brief		: adc2ftd_02 top
-- author(s)	: marc at pignat dot org
-- license		: The MIT License (MIT) (http://opensource.org/licenses/MIT)
--				  Copyright (c) 2015 Marc Pignat
--
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
		-- Mimas
		clk				: in	std_ulogic;
		sw				: in	std_ulogic_vector(3 downto 0);
		led				: out	std_ulogic_vector(7 downto 0);
		
		-- FT2232h
		FT_CLKOUT		: in	std_ulogic;
		FT_DATA			: inout	std_logic_vector(7 downto 0);
		FT_nRESET		: out	std_ulogic;
		FT_nTXE			: in	std_ulogic;
		FT_nRXF			: in	std_ulogic;
		FT_nWR			: out	std_ulogic;
		FT_nRD			: out	std_ulogic;
		FT_SIWUA		: out	std_ulogic;
		FT_nOE			: out	std_ulogic;
		FT_nSUSPEND		: in	std_ulogic;
		
		-- ADCs
		sclk			: out	std_ulogic;
		n_cs			: out	std_ulogic;
		sdata			: in	std_ulogic_vector(g_parallel-1 downto 0);
		
		reset			: in	std_ulogic
	);
begin end;

architecture rtl of top is
	signal clock			: std_ulogic;
	
	signal read_data		: std_ulogic_vector(FT_DATA'range);
	signal read_valid		: std_ulogic;
	signal ftd_data			: std_ulogic_vector(FT_DATA'range);
	signal ftd_read			: std_ulogic;
	signal ftd_empty		: std_ulogic;
	
	signal adc_data48		: std_ulogic_vector(g_parallel*12-1 downto 0);
	signal adc_data64		: std_ulogic_vector(g_parallel*16-1 downto 0);
	signal adc_data_valid	: std_ulogic;
	signal adc_data8		: std_ulogic_vector(7 downto 0);
	signal adc_data8_valid	: std_ulogic;
begin

clock <= not FT_CLKOUT;

i_ft245: entity work.ft245_sync_if
port map
(
	adbus			=> FT_DATA,
	rxf_n			=> FT_nRXF,
	txe_n			=> FT_nTXE,
	rd_n			=> FT_nRD,
	wr_n			=> FT_nWR,
	clock			=> clock,
	oe_n			=> FT_nOE,
	siwu			=> FT_SIWUA,
	reset_n			=> FT_nRESET,
	suspend_n		=> FT_nSUSPEND,
	
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
		adc_data64((16*(i+1))-1 downto 16*i) <= adc_data48((12*(i+1))-1 downto 12*i) & "0000";
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
	g_depth_in_log2		=> 2,
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