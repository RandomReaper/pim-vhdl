-----------------------------------------------------------------------------
-- file		: clock.vhd 
--
-- brief		: Simulate a FT2232H in FT245 Synchronous fifo mode
-- author(s)	: marc at pignat dot org
-- license		: The MIT License (MIT) (http://opensource.org/licenses/MIT)
--				  Copyright (c) 2015 Marc Pignat
-----------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity ft245_sync_sim is
	port
	(
		adbus		: inout	std_logic_vector(7 downto 0);
		rxf_n		: out	std_ulogic;
		txe_n		: out	std_ulogic;
		rd_n		: in	std_ulogic;
		wr_n		: in	std_ulogic;
		clkout		: out	std_ulogic;
		oe_n		: in	std_ulogic;
		siwu		: in	std_ulogic;
		reset_n		: in	std_ulogic;
		sudpend_n	: out	std_ulogic
	);
end ft245_sync_sim ;

architecture bhv of ft245_sync_sim is
	signal reset	: std_ulogic;
	signal oe		: std_ulogic;
	signal data_in	: std_ulogic_vector(adbus'range);
	signal clock	: std_ulogic;
begin

reset	<= not reset_n;
oe		<= not oe_n;
clkout	<= clock;

hi_z: process(oe, data_in)
begin
	if oe = '1' then
		adbus <= std_logic_vector(data_in);
	else
		adbus <= (others => 'Z');
	end if;
end process;

i_clock: entity work.clock
	generic map
	(
		frequency => 60.0e6
	)
	port map
	(
		clock	=> clock
	);

end architecture bhv;
