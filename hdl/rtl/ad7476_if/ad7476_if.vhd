-----------------------------------------------------------------------------
-- file			: ad7476_if.vhd 
--
-- brief		: adc7476 interface
-- author(s)	: marc at pignat dot org
-- license		: The MIT License (MIT) (http://opensource.org/licenses/MIT)
--				  Copyright (c) 2015 Marc Pignat
--
-----------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity ad7476_if is
port
(
	clock	: in	std_ulogic;
	reset	: in	std_ulogic;
	
	-- To the adc7476
	sclk		: out	std_ulogic;
	n_cs		: out	std_ulogic;
	sdata		: in	std_ulogic;
	
	-- To the internal logic
	
	data		: out	std_ulogic_vector(11 downto 0);
	data_valid	: out	std_ulogic
);
end ad7476_if;

architecture rtl of ad7476_if is
begin


end rtl;
