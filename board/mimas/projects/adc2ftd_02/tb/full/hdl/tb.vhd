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
generic
(
	g_parallel : natural := 4
);
end tb;

architecture bhv of tb is
	signal reset			: std_ulogic;

	signal FT_CLKOUT		: std_ulogic;
	alias  clock is FT_CLKOUT;
	signal FT_DATA			: std_logic_vector(7 downto 0);
	signal FT_nRESET		: std_ulogic;
	signal FT_nTXE			: std_ulogic;
	signal FT_nRXF			: std_ulogic;
	signal FT_nWR			: std_ulogic;
	signal FT_nRD			: std_ulogic;
	signal FT_SIWUA			: std_ulogic;
	signal FT_nOE			: std_ulogic;
	signal FT_nSUSPEND		: std_ulogic;
	
	-- ADCs
	signal sclk				: std_ulogic;
	signal n_cs				: std_ulogic;
	signal sdata			: std_ulogic_vector(g_parallel-1 downto 0);	
begin

i_top: entity work.top
generic map
(
	g_parallel	=> g_parallel
)
port map
(
	-- Mimas
	clk				=> '0',
	sw				=> x"0",
	led				=> open,
	
	-- FT2232h
	FT_CLKOUT		=> FT_CLKOUT,
	FT_DATA			=> FT_DATA,
	FT_nRESET		=> FT_nRESET,
	FT_nTXE			=> FT_nTXE,
	FT_nRXF			=> FT_nRXF,
	FT_nWR			=> FT_nWR,
	FT_nRD			=> FT_nRD,
	FT_SIWUA		=> FT_SIWUA,
	FT_nOE			=> FT_nOE,
	FT_nSUSPEND		=> FT_nSUSPEND,
	
	-- ADCs
	sclk			=> sclk,
	n_cs			=> n_cs,
	sdata			=> sdata,
	
	reset			=> reset
);

i_ft245_sim: entity work.ft245_sync_sim
port map
(
	adbus			=> FT_DATA,
	rxf_n			=> FT_nRXF,
	txe_n			=> FT_nTXE,
	rd_n			=> FT_nRD,
	wr_n			=> FT_nWR,
	clkout			=> FT_CLKOUT,
	oe_n			=> FT_nOE,
	siwu			=> FT_SIWUA,
	reset_n			=> FT_nRESET,
	suspend_n		=> FT_nSUSPEND,

	d_data_out		=> open,
	d_data_in		=> x"00",
	d_data_write	=> '0',
	d_data_full		=> open
);

i_ad7476_parallel_sim: entity work.ad7476_parallel_sim
generic map
(
	g_parallel	=> g_parallel
)
port map
(
	sclk			=> sclk,
	n_cs			=> n_cs,
	sdata			=> sdata
);

i_reset: entity work.reset
port map
(
	reset	=> reset,
	clock	=> clock
);
end bhv;
