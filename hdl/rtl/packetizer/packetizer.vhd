-----------------------------------------------------------------------------
-- file			: packetizer.vhd 
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

entity packetizer is
generic
(
	g_parallel : natural := 1
);
port
(
	clock			: in	std_ulogic;
	reset			: in	std_ulogic;
	
	adc_data		: in	std_ulogic_vector(g_parallel*12-1 downto 0);
	adc_data_valid	: in	std_ulogic;
	tx_data			: out	std_ulogic_vector(7 downto 0);
	tx_data_valid	: out	std_ulogic
);
end packetizer;

architecture rtl of packetizer is
begin

end rtl;
