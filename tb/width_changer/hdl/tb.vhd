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
end tb;

architecture bhv of tb is
	signal reset			: std_ulogic;
	signal clock			: std_ulogic;
	
	signal data8			: std_ulogic_vector(7 downto 0);
	signal data8_valid		: std_ulogic;
	signal data2			: std_ulogic_vector(1 downto 0);
	signal data2_valid		: std_ulogic;
begin

i_smaller_1: entity work.width_changer
port map
(
	reset			=> reset,
	clock			=> clock,
	
	in_data			=> data8,
	in_data_valid	=> data8_valid,
	in_data_ready	=> open,
	out_data		=> data2,
	out_data_valid	=> data2_valid
);

data8 <= x"aa";
data8_valid <= '1';

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
