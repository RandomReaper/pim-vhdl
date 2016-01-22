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
	g_parallel	: natural := 2
);
end tb;

architecture bhv of tb is
	signal reset			: std_ulogic;
	signal clock			: std_ulogic;
	
	signal sclk				: std_ulogic;
	signal n_cs				: std_ulogic;
	signal sdata			: std_ulogic_vector(g_parallel-1 downto 0);
begin

i_adc_if : entity work.ad7476_parallel_if
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
	
	data		=> open,
	data_valid	=> open
);

i_adc_sim : entity work.ad7476_parallel_sim
generic map
(
	g_parallel	=> g_parallel
)
port map
(
	sclk	=> sclk,
	n_cs	=> n_cs,
	sdata	=> sdata
);

i_clock : entity work.clock
generic map
(
	frequency	=> 80.0e6
)
port map
(
	clock	=> clock
);

i_reset : entity work.reset
port map
(
	reset	=> reset,
	clock	=> clock
);

end bhv;
