-----------------------------------------------------------------------------
-- file			: ad7476_parallel_if.vhd 
--
-- brief		: adc7476 interface
-- author(s)	: marc at pignat dot org
-- license		: The MIT License (MIT) (http://opensource.org/licenses/MIT)
--				  Copyright (c) 2015 Marc Pignat
--
-- limitations	: uses a 2^prescaler clock (prescaler >= 1)
--
-----------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity ad7476_parallel_if is
generic
(
	g_prescaler	: natural := 1;
	g_parallel	: natural := 2
);
port
(
	clock	: in	std_ulogic;
	reset	: in	std_ulogic;
	
	-- To the adc7476
	sclk		: out	std_ulogic;
	n_cs		: out	std_ulogic;
	sdata		: in	std_ulogic_vector(g_parallel-1 downto 0);
	
	-- To the internal logic
	
	data		: out	std_ulogic_vector((12*g_parallel)-1 downto 0);
	data_valid	: out	std_ulogic
);
end ad7476_parallel_if;

architecture rtl of ad7476_parallel_if is
begin
gen_adc_if: for i in 0 to g_parallel-1 generate
	a: if i = 0 generate
		i_adc_x: entity work.ad7476_if
		generic map
		(
			g_prescaler	=> g_prescaler
		)
		port map
		(
			reset	=> reset,
			clock	=> clock,
			
			sdata	=> sdata(i),
			data	=> data((12*(i+1))-1 downto 12*i),
			data_valid => data_valid,
			n_cs	=> n_cs,
			sclk	=> sclk
		);	
	end generate;
	
	b: if i > 0 generate
		i_adc_x: entity work.ad7476_if
		generic map
		(
			g_prescaler	=> g_prescaler
		)
		port map
		(
			reset	=> reset,
			clock	=> clock,
			
			sdata	=> sdata(i),
			data	=> data((12*(i+1))-1 downto 12*i),
			data_valid => open
		);
	end generate;
end generate;
end rtl;
