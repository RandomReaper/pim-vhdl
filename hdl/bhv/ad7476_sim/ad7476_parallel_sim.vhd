-----------------------------------------------------------------------------
-- file			: ad7476_parallel_sim.vhd 
--
-- brief		: ad7476 (for simulation)
-- author(s)	: marc at pignat dot org
-- license		: The MIT License (MIT) (http://opensource.org/licenses/MIT)
--				  Copyright (c) 2015 Marc Pignat
-----------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity ad7476_parallel_sim is
generic
(
	g_parallel	: natural := 2
);
port
(
	sclk		: in	std_ulogic;
	n_cs		: in	std_ulogic;
	sdata		: out	std_ulogic_vector(g_parallel-1 downto 0)
);
end ad7476_parallel_sim;

architecture bhv of ad7476_parallel_sim is
begin
gen_adc_sim: for i in 0 to g_parallel-1 generate
	i_adc_sim_x: entity work.ad7476_sim
		port map
		(
			sdata	=> sdata(i),
			n_cs	=> n_cs,
			sclk	=> sclk
		);
end generate;
end architecture bhv;
