-----------------------------------------------------------------------------
-- file			: clock_stop.vhd
--
-- brief		: Stoppable clock generator (will halt most simulators)
-- author(s)	: marc at pignat dot org
-----------------------------------------------------------------------------
-- Copyright 2015,2016 Marc Pignat
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- 		http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- See the License for the specific language governing permissions and
-- limitations under the License.
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

	assert false report "PIM_VHDL_SIMULATION_DONE" severity note;

	wait;

end process;

end architecture bhv;
