-----------------------------------------------------------------------------
-- file			: ad7476_sim.vhd 
--
-- brief		: ad7476 (for simulation)
-- author(s)	: marc at pignat dot org
-- license		: The MIT License (MIT) (http://opensource.org/licenses/MIT)
--				  Copyright (c) 2015 Marc Pignat
-----------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity ad7476_sim is
port
(
	sclk		: in	std_ulogic;
	n_cs		: in	std_ulogic;
	sdata		: out	std_ulogic
);
end ad7476_sim;

architecture bhv of ad7476_sim is
	alias clock is sclk;
	signal reset : std_ulogic;
begin

i_reset : entity work.reset
generic map
(
	clock_duration => 1
)
port map
(
	reset	=> reset,
	clock	=> clock
);

end architecture bhv;
