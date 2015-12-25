-----------------------------------------------------------------------------
-- file			: clock.vhd 
--
-- brief		: Clock generator (for simulation)
-- author(s)	: marc at pignat dot org
-- license		: The MIT License (MIT) (http://opensource.org/licenses/MIT)
--				  Copyright (c) 2015 Marc Pignat
-----------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity clock is
	generic
	(
		frequency	: real	:= 1.0e6
	);
	port
	(
		clock		: out	std_ulogic
	);
end clock;

architecture bhv of clock is
	constant period : time := (1.0 / frequency) * (1 sec);
begin

clock_gen : process is
begin
	clock <= '0';
	wait for period / 2;
	clock <= '1';
	wait for period / 2;
end process;

end architecture bhv;
