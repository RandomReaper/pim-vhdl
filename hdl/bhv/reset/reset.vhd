-----------------------------------------------------------------------------
-- file			: reset.vhd 
--
-- brief		: Reset generator (for simulation)
-- author(s)	: marc at pignat dot org
-- license		: The MIT License (MIT) (http://opensource.org/licenses/MIT)
--				  Copyright (c) 2015 Marc Pignat
-----------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity reset is
	generic
	(
		clock_duration : natural := 5
	);
	port
	(
		clock : in     std_ulogic;
		reset : out    std_ulogic
	);
end reset;

architecture bhv of reset is
	signal counter : natural;
begin

counter_gen: process(clock)
begin
	if rising_edge(clock) then
		if counter < clock_duration then
			counter <= counter + 1;
		end if;
	end if;
end process;

reset_gen: process(counter)
begin
	if counter < clock_duration then
		reset <= '1';
	else
		reset <= '0';
	end if;
end process;

end architecture bhv;
