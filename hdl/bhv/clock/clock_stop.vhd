-----------------------------------------------------------------------------
-- file			: clock_stop.vhd 
--
-- brief		: Stoppable clock generator (will halt most simulator)
-- author(s)	: marc at pignat dot org
-- license		: The MIT License (MIT) (http://opensource.org/licenses/MIT)
--				  Copyright (c) 2015 Marc Pignat
-----------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity clock_stop is
	generic
	(
		frequency	: real	:= 1.0e6
	);
	port
	(
		stop		: in	std_ulogic;
		clock		: out	std_ulogic
	);
end clock_stop;

architecture bhv of clock_stop is
	constant period : time := (1.0 / frequency) * (1 sec);
begin

clock_gen : process is
begin
	while stop /= '1' loop
		clock <= '0';
		wait for period / 2;
		clock <= '1';
		wait for period / 2;
	end loop;
	
	clock <= '0';
	
	assert false report "Simulation Done" severity note;

	wait;
	
end process;

end architecture bhv;
